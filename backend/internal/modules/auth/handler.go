package auth

import (
	"fmt"

	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/middleware"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type SignupRequest struct {
	CompanyName string `json:"company_name"`
	Slug        string `json:"slug"`
	OwnerName   string `json:"owner_name"`
	Email       string `json:"email"`
	Password    string `json:"password"`
}

var authSvc = &AuthService{}

func Login(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	user, token, err := authSvc.Login(req.Email, req.Password)
	if err != nil {
		if err == ErrTenantInactive {
			return core.SendError(c, fiber.StatusForbidden, "SaaS Workspace is deactivated. Contact SuperAdmin Helpdesk.", err)
		}
		return core.SendError(c, fiber.StatusUnauthorized, err.Error(), err)
	}

	return c.JSON(fiber.Map{
		"token": token,
		"user":  user,
	})
}

func RefreshToken(c *fiber.Ctx) error {
	// The user is already authenticated via AuthRequired middleware
	userID := c.Locals("user_id").(uint)
	email := c.Locals("email").(string)
	role := c.Locals("role").(string)
	var tenantID *uint
	if tid := c.Locals("tenant_id"); tid != nil {
		id := tid.(uint)
		tenantID = &id
	}

	// Verify user still exists and is active
	var user models.User
	if err := db.DB.Preload("Tenant").First(&user, userID).Error; err != nil {
		return core.SendError(c, fiber.StatusUnauthorized, "User no longer exists", err)
	}
	if user.Tenant != nil && !user.Tenant.IsActive {
		return core.SendError(c, fiber.StatusForbidden, "SaaS Workspace is deactivated", nil)
	}

	newToken, err := middleware.GenerateToken(userID, email, role, tenantID)
	if err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to generate token", err)
	}

	return c.JSON(fiber.Map{
		"token": newToken,
	})
}

func SignupTenant(c *fiber.Ctx) error {
	var req SignupRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.CompanyName = core.Sanitize(req.CompanyName)
	req.OwnerName = core.Sanitize(req.OwnerName)
	req.Email = core.Sanitize(req.Email)
	req.Slug = core.Sanitize(req.Slug)

	input := SignupInput{
		CompanyName: req.CompanyName,
		Slug:        req.Slug,
		OwnerName:   req.OwnerName,
		Email:       req.Email,
		Password:    req.Password,
	}

	user, token, err := authSvc.Signup(input)
	if err != nil {
		if err == ErrEmailExists || err == ErrSlugExists {
			return core.SendError(c, fiber.StatusConflict, err.Error(), err)
		}
		return core.SendError(c, fiber.StatusBadRequest, err.Error(), err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"token": token,
		"user":  user,
	})
}

func GetMe(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	user, err := authSvc.GetUser(userID)
	if err != nil {
		return core.SendError(c, fiber.StatusNotFound, "User not found", err)
	}
	return c.JSON(user)
}

type UpdateProfileRequest struct {
	Name  string `json:"name"`
	Phone string `json:"phone"`
}

func UpdateProfile(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	var req UpdateProfileRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Name = core.Sanitize(req.Name)
	req.Phone = core.Sanitize(req.Phone)

	if req.Name == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Name is required", nil)
	}

	user, err := authSvc.UpdateProfile(userID, req.Name, req.Phone)
	if err != nil {
		return core.SendError(c, fiber.StatusNotFound, err.Error(), err)
	}

	return c.JSON(fiber.Map{
		"id":         user.ID,
		"name":       user.Name,
		"email":      user.Email,
		"phone":      user.Phone,
		"avatar_url": user.AvatarURL,
		"role":       user.Role,
		"tenant_id":  user.TenantID,
	})
}

type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password"`
	NewPassword     string `json:"new_password"`
}

func ChangePassword(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	var req ChangePasswordRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	if req.CurrentPassword == "" || req.NewPassword == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Current and new password are required", nil)
	}
	if !ValidatePassword(req.NewPassword) {
		return core.SendError(c, fiber.StatusBadRequest, "New password must be 8+ chars with uppercase, lowercase, digit and special character", nil)
	}
	if req.CurrentPassword == req.NewPassword {
		return core.SendError(c, fiber.StatusBadRequest, "New password must be different from current password", nil)
	}

	if err := authSvc.ChangePassword(userID, req.CurrentPassword, req.NewPassword); err != nil {
		if err == ErrUserNotFound {
			return core.SendError(c, fiber.StatusNotFound, "User not found", err)
		}
		return core.SendError(c, fiber.StatusUnauthorized, err.Error(), err)
	}

	return c.JSON(fiber.Map{"message": "Password changed successfully"})
}

type ForgotPasswordRequest struct {
	Email string `json:"email"`
}

func ForgotPassword(c *fiber.Ctx) error {
	var req ForgotPasswordRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Email = core.Sanitize(req.Email)
	if req.Email == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Email is required", nil)
	}

	_, err := authSvc.ForgotPassword(req.Email)
	if err != nil {
		fmt.Printf("Forgot password error for %s: %v\n", req.Email, err)
	}

	// Always return the same message to prevent email enumeration
	return c.JSON(fiber.Map{"message": "Password reset link sent to email"})
}

type ResetPasswordRequest struct {
	Token       string `json:"token"`
	NewPassword string `json:"new_password"`
}

func ResetPassword(c *fiber.Ctx) error {
	var req ResetPasswordRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	if req.Token == "" || req.NewPassword == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Token and new password are required", nil)
	}

	if !ValidatePassword(req.NewPassword) {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character",
		})
	}

	if err := authSvc.ResetPassword(req.Token, req.NewPassword); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, err.Error(), err)
	}

	return c.JSON(fiber.Map{"message": "Password reset successfully"})
}

type InviteUserRequest struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"`
	Role     string `json:"role"`
}

func InviteUser(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	var req InviteUserRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Name = core.Sanitize(req.Name)
	req.Email = core.Sanitize(req.Email)
	req.Role = core.Sanitize(req.Role)

	if req.Name == "" || req.Email == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Name and email are required", nil)
	}

	input := InviteUserInput{
		Name:     req.Name,
		Email:    req.Email,
		Password: req.Password,
		Role:     req.Role,
	}

	user, err := authSvc.InviteUser(tenantID, input)
	if err != nil {
		if err == ErrEmailExists {
			return core.SendError(c, fiber.StatusConflict, "Email already registered", err)
		}
		return core.SendError(c, fiber.StatusBadRequest, err.Error(), err)
	}

	user.PasswordHash = ""
	return c.Status(fiber.StatusCreated).JSON(user)
}

func ListUsers(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	offset, limit := core.GetPagination(c)
	users, err := authSvc.ListUsers(tenantID, offset, limit)
	if err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch users", err)
	}
	return c.JSON(users)
}

func DeleteUser(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	userID := c.Params("id")
	requesterID := c.Locals("user_id").(uint)

	// Parse userID string to uint for the service layer
	var uid uint
	if _, err := fmt.Sscanf(userID, "%d", &uid); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid user ID", err)
	}

	if err := authSvc.DeleteUser(tenantID, uid, requesterID); err != nil {
		if err == ErrUserNotFound {
			return core.SendError(c, fiber.StatusNotFound, "User not found", err)
		}
		return core.SendError(c, fiber.StatusForbidden, err.Error(), err)
	}
	return c.JSON(fiber.Map{"message": "User removed from workspace"})
}

type UpdateUserRequest struct {
	Name  string `json:"name"`
	Role  string `json:"role"`
	Phone string `json:"phone"`
}

func UpdateUser(c *fiber.Ctx) error {
	id := c.Params("id")
	tenantID := c.Locals("tenant_id_value").(uint)

	var req UpdateUserRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Name = core.Sanitize(req.Name)
	req.Phone = core.Sanitize(req.Phone)

	user, err := authSvc.UpdateUser(tenantID, id, req.Name, req.Role, req.Phone)
	if err != nil {
		if err == ErrUserNotFound {
			return core.SendError(c, fiber.StatusNotFound, "User not found", err)
		}
		return core.SendError(c, fiber.StatusForbidden, err.Error(), err)
	}

	return c.JSON(fiber.Map{
		"id":    user.ID,
		"name":  user.Name,
		"email": user.Email,
		"role":  user.Role,
		"phone": user.Phone,
	})
}
