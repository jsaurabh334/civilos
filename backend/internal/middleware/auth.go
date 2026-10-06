package middleware

import (
	"fmt"
	"os"
	"strings"
	"time"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

func GetJWTSecret() []byte {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		panic("JWT_SECRET environment variable is not set. A secure secret must be provided.")
	}
	return []byte(secret)
}

type Claims struct {
	UserID   uint   `json:"user_id"`
	Email    string `json:"email"`
	Role     string `json:"role"`
	TenantID *uint  `json:"tenant_id,omitempty"`
	jwt.RegisteredClaims
}

func GenerateToken(userID uint, email string, role string, tenantID *uint) (string, error) {
	claims := Claims{
		UserID:   userID,
		Email:    email,
		Role:     role,
		TenantID: tenantID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(GetJWTSecret())
}

func AuthRequired(c *fiber.Ctx) error {
	authHeader := c.Get("Authorization")
	tokenStr := c.Query("token")

	if authHeader != "" {
		parts := strings.Split(authHeader, " ")
		if len(parts) == 2 && parts[0] == "Bearer" {
			tokenStr = parts[1]
		}
	} else if subProtocol := c.Get("Sec-WebSocket-Protocol"); subProtocol != "" {
		// Some WebSocket clients send the token as a subprotocol to avoid URL leakage
		tokenStr = strings.Split(subProtocol, ",")[0]
		tokenStr = strings.TrimSpace(tokenStr)
	}

	if tokenStr == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Authorization header or token query param is required"})
	}
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return GetJWTSecret(), nil
	})

	if err != nil || token == nil || !token.Valid {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid or expired token"})
	}

	claims, ok := token.Claims.(*Claims)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid token claims"})
	}

	c.Locals("user_id", claims.UserID)
	c.Locals("email", claims.Email)
	c.Locals("role", claims.Role)
	c.Locals("tenant_id", claims.TenantID)

	return c.Next()
}

func RequireRoles(roles ...string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		roleVal := c.Locals("role")
		if roleVal == nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "User role not found"})
		}

		userRole := roleVal.(string)
		for _, role := range roles {
			if userRole == role {
				return c.Next()
			}
		}

		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Access forbidden: insufficient permissions"})
	}
}

// TenantScope verifies the user is tied to a valid tenant (or is SuperAdmin)
func TenantScope(c *fiber.Ctx) error {
	roleVal := c.Locals("role")
	tenantIDVal := c.Locals("tenant_id")

	if roleVal == nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "User role not found"})
	}

	role := roleVal.(string)
	if role == "SuperAdmin" {
		// SuperAdmin is exempt from automatic tenant scoping, but we must inject a default dummy value
		// to prevent nil type assertion crashes in GORM filter queries
		c.Locals("tenant_id_value", uint(0))
		return c.Next()
	}

	if tenantIDVal == nil {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Tenant access required"})
	}

	var tenantID uint
	tenantIDPtr, ok := tenantIDVal.(*uint)
	if !ok || tenantIDPtr == nil {
		tIDDirect, okDirect := tenantIDVal.(uint)
		if okDirect {
			tenantID = tIDDirect
		} else {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Invalid tenant assignment"})
		}
	} else {
		tenantID = *tenantIDPtr
	}

	// Verify tenant is active in database (Active Subscription lock)
	var dbTenant models.Tenant
	if err := db.DB.First(&dbTenant, tenantID).Error; err != nil {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Tenant workspace not found"})
	}
	if !dbTenant.IsActive {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "SaaS Workspace is deactivated. Contact SuperAdmin Helpdesk."})
	}

	c.Locals("tenant_id_value", tenantID)
	return c.Next()
}
