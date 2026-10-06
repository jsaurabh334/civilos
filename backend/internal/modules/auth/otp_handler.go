package auth

import (
	"crypto/rand"
	"fmt"
	"math/big"
	"sync"
	"time"

	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/middleware"
	"civilos/backend/internal/models"
	"civilos/backend/internal/modules/notifications"
	"log/slog"

	"github.com/gofiber/fiber/v2"
)

// ─── In-memory OTP store (use Redis in production) ────────────────────────────

type otpEntry struct {
	Code      string
	Email     string
	ExpiresAt time.Time
}

var (
	otpStore   = map[string]otpEntry{}
	otpStoreMu sync.RWMutex
)

func init() {
	go func() {
		ticker := time.NewTicker(5 * time.Minute)
		for range ticker.C {
			otpStoreMu.Lock()
			for k, v := range otpStore {
				if time.Now().After(v.ExpiresAt) {
					delete(otpStore, k)
				}
			}
			otpStoreMu.Unlock()
		}
	}()
}

func generateOTP() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

// SendOTP generates a 6-digit OTP and (in production) sends it by email/SMS.
// In development, the OTP is returned in the response for easy testing.
func SendOTP(c *fiber.Ctx) error {
	type req struct {
		Email string `json:"email"`
	}
	var body req
	if err := c.BodyParser(&body); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}
	body.Email = core.Sanitize(body.Email)
	if body.Email == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Email is required", nil)
	}

	// Check user exists
	var user models.User
	if err := db.DB.Where("email = ?", body.Email).First(&user).Error; err != nil {
		// Return success anyway to prevent email enumeration
		return c.JSON(fiber.Map{"message": "If the email is registered, you will receive an OTP"})
	}

	otp, err := generateOTP()
	if err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to generate OTP", err)
	}

	otpStoreMu.Lock()
	otpStore[body.Email] = otpEntry{Code: otp, Email: body.Email, ExpiresAt: time.Now().Add(10 * time.Minute)}
	otpStoreMu.Unlock()

	// Send OTP via email
	if err := notifications.Email.SendOTPEmail(body.Email, otp); err != nil {
		slog.Error("failed to send OTP email", slog.String("email", body.Email), slog.String("error", err.Error()))
	}

	return c.JSON(fiber.Map{
		"message": "OTP sent successfully",
	})
}

// VerifyOTP validates the OTP and returns a session token.
func VerifyOTP(c *fiber.Ctx) error {
	type req struct {
		Email string `json:"email"`
		OTP   string `json:"otp"`
	}
	var body req
	if err := c.BodyParser(&body); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}
	body.Email = core.Sanitize(body.Email)

	otpStoreMu.Lock()
	entry, ok := otpStore[body.Email]
	if !ok || entry.Code != body.OTP {
		otpStoreMu.Unlock()
		return core.SendError(c, fiber.StatusUnauthorized, "Invalid or expired OTP", nil)
	}
	if time.Now().After(entry.ExpiresAt) {
		delete(otpStore, body.Email)
		otpStoreMu.Unlock()
		return core.SendError(c, fiber.StatusUnauthorized, "OTP has expired. Please request a new one.", nil)
	}

	// Consume the OTP
	delete(otpStore, body.Email)
	otpStoreMu.Unlock()

	// Find the user
	var user models.User
	if err := db.DB.Preload("Tenant").Where("email = ?", body.Email).First(&user).Error; err != nil {
		return core.SendError(c, fiber.StatusUnauthorized, "User not found", err)
	}
	if user.Tenant != nil && !user.Tenant.IsActive {
		return core.SendError(c, fiber.StatusForbidden, "Workspace is deactivated", nil)
	}

	token, err := middleware.GenerateToken(user.ID, user.Email, user.Role, user.TenantID)
	if err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to generate token", err)
	}

	return c.JSON(fiber.Map{
		"token": token,
		"user":  user,
	})
}
