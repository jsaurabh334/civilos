package auth

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"
	"time"

	"github.com/gofiber/fiber/v2"
)

type UpdateLocationRequest struct {
	Latitude  float64 `json:"latitude" validate:"required"`
	Longitude float64 `json:"longitude" validate:"required"`
}

// UpdateLocation allows the supervisor to constantly ping their location
func UpdateLocation(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)

	var req UpdateLocationRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	now := time.Now()
	if err := db.DB.Model(&models.User{}).Where("id = ?", userID).Updates(map[string]interface{}{
		"last_latitude":        req.Latitude,
		"last_longitude":       req.Longitude,
		"last_location_update": now,
	}).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update location", err)
	}

	return c.JSON(fiber.Map{"status": "Location updated successfully"})
}
