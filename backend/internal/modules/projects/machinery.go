package projects

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"
	"time"

	"github.com/gofiber/fiber/v2"
)

// ListMachinery lists all machinery for the tenant
func ListMachinery(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	machinery := []models.Machinery{}
	if err := db.DB.Where("tenant_id = ?", tenantID).Find(&machinery).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch machinery", err)
	}

	return c.JSON(machinery)
}

type CreateMachineryRequest struct {
	Name string `json:"name" validate:"required"`
	Type string `json:"type"`
}

func CreateMachinery(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	var req CreateMachineryRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request", err)
	}
	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	mach := models.Machinery{
		TenantID: tenantID,
		Name:     req.Name,
		Type:     req.Type,
	}

	if err := db.DB.Create(&mach).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to create machinery", err)
	}

	return c.JSON(fiber.Map{"message": "Machinery added", "machinery": mach})
}

type LogMachineryRequest struct {
	ProjectID  uint    `json:"project_id" validate:"required"`
	UsageHours float64 `json:"usage_hours"`
	FuelEntry  float64 `json:"fuel_entry"`
}

func LogMachinery(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	userID := c.Locals("user_id").(uint)
	machID := c.Params("id")

	var req LogMachineryRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request", err)
	}
	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	var mID uint
	if err := db.DB.Model(&models.Machinery{}).Where("id = ? AND tenant_id = ?", machID, tenantID).Pluck("id", &mID).Error; err != nil || mID == 0 {
		return core.SendError(c, fiber.StatusNotFound, "Machinery not found", err)
	}

	log := models.MachineryLog{
		TenantID:    &tenantID,
		MachineryID: mID,
		ProjectID:   &req.ProjectID,
		UsageHours:  req.UsageHours,
		FuelEntry:   req.FuelEntry,
		LoggedByID:  userID,
		Date:        time.Now().UTC().Format("2006-01-02"),
	}

	if err := db.DB.Create(&log).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to log machinery", err)
	}

	return c.JSON(fiber.Map{"message": "Machinery logged", "log": log})
}
