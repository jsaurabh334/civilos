package auth

import (
	"civilos/backend/internal/core"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func RegisterFCMToken(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)

	var body struct {
		Token string `json:"token"`
	}
	if err := c.BodyParser(&body); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}
	if body.Token == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Token is required", nil)
	}

	if err := db.DB.Model(&models.User{}).Where("id = ?", userID).Update("fcm_token", body.Token).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to register token", err)
	}

	return c.JSON(fiber.Map{"message": "FCM token registered"})
}
