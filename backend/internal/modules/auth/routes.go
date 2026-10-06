package auth

import (
	"civilos/backend/internal/middleware"

	"github.com/gofiber/fiber/v2"
)

func RegisterRoutes(api fiber.Router, protected fiber.Router, tenantSpace fiber.Router) {
	authGroup := api.Group("/auth", middleware.AuthLimiter())
	authGroup.Post("/login", Login)
	authGroup.Post("/signup", SignupTenant)
	authGroup.Post("/forgot-password", ForgotPassword)
	authGroup.Post("/reset-password", ResetPassword)
	authGroup.Post("/send-otp", SendOTP)
	authGroup.Post("/verify-otp", VerifyOTP)

	protected.Get("/auth/me", GetMe)
	protected.Post("/auth/refresh", RefreshToken)
	protected.Put("/auth/profile", UpdateProfile)
	protected.Put("/auth/password", ChangePassword)
	protected.Post("/auth/fcm-token", RegisterFCMToken)

	tenantSpace.Get("/users", ListUsers)
	tenantSpace.Post("/users/invite", middleware.RequireRoles("Contractor"), InviteUser)
	tenantSpace.Delete("/users/:id", middleware.RequireRoles("Contractor"), DeleteUser)
	tenantSpace.Put("/users/:id", middleware.RequireRoles("Contractor"), UpdateUser)
}
