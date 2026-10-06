package projects

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"
	"time"

	"github.com/gofiber/fiber/v2"
)

type LocationPingRequest struct {
	Latitude  float64 `json:"latitude" validate:"required"`
	Longitude float64 `json:"longitude" validate:"required"`
	Accuracy  float64 `json:"accuracy"`
}

func PingSupervisorLocation(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	supervisorID := c.Locals("user_id").(uint)

	var req LocationPingRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	loc := models.SupervisorLocation{
		TenantID:     tenantID,
		SupervisorID: supervisorID,
		Latitude:     req.Latitude,
		Longitude:    req.Longitude,
		Accuracy:     req.Accuracy,
		Timestamp:    time.Now().UTC(),
	}

	if err := db.DB.Create(&loc).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to save location", err)
	}

	// Update the user's latest coordinates for quick joins
	db.DB.Model(&models.User{}).Where("id = ?", supervisorID).Updates(map[string]interface{}{
		"latitude":             req.Latitude,
		"longitude":            req.Longitude,
		"last_location_update": loc.Timestamp,
	})

	return c.JSON(fiber.Map{"message": "Location pinged successfully"})
}

func GetLiveSupervisorLocations(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	// Fetch all supervisors for this tenant who have pinged their location recently
	supervisors := []models.User{}
	if err := db.DB.Where("tenant_id = ? AND role = ? AND last_location_update IS NOT NULL", tenantID, "Supervisor").Find(&supervisors).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch supervisors", err)
	}

	return c.JSON(supervisors)
}
