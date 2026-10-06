package admin

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

type UpdateSettingRequest struct {
	Key   string `json:"key" validate:"required"`
	Value string `json:"value" validate:"required"`
}

func UpdatePlatformSetting(c *fiber.Ctx) error {
	var req UpdateSettingRequest

	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	var setting models.PlatformSetting
	err := db.DB.Where("key = ?", req.Key).First(&setting).Error
	if err != nil {
		// Create if doesn't exist
		setting = models.PlatformSetting{
			Key:   req.Key,
			Value: req.Value,
		}
	} else {
		setting.Value = req.Value
	}

	if err := db.DB.Save(&setting).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update setting", err)
	}

	db.LogAudit("SuperAdmin", "Global", "Updated platform setting: "+req.Key, c.IP())

	return c.JSON(fiber.Map{"message": "Setting updated successfully", "setting": setting})
}

func ListPlatformSettings(c *fiber.Ctx) error {
	settings := []models.PlatformSetting{}

	if err := db.DB.Find(&settings).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch settings", err)
	}

	return c.JSON(settings)
}
