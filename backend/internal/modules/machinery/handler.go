package machinery

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func ListMachinery(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	machinery := []models.Machinery{}
	offset, limit := core.GetPagination(c)

	if err := db.DB.Where("tenant_id = ?", tenantID).Offset(offset).Limit(limit).Find(&machinery).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch fleet machinery", err)
	}

	return c.JSON(machinery)
}

type CreateMachineryRequest struct {
	Name        string  `json:"name"`
	ModelNumber string  `json:"model_number"`
	HourlyRate  float64 `json:"hourly_rate"`
}

func CreateMachinery(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	var req CreateMachineryRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Name = core.Sanitize(req.Name)
	req.ModelNumber = core.Sanitize(req.ModelNumber)

	if req.Name == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Machinery name is required", nil)
	}

	if req.HourlyRate <= 0 {
		return core.SendError(c, fiber.StatusBadRequest, "Hourly rate must be greater than zero", nil)
	}

	mac := models.Machinery{
		TenantID:      tenantID,
		Name:          req.Name,
		ModelNumber:   req.ModelNumber,
		HourlyRate:    req.HourlyRate,
		TotalHoursRun: 0,
		Status:        "Active",
	}

	if err := db.DB.Create(&mac).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to register machinery", err)
	}

	return c.Status(fiber.StatusCreated).JSON(mac)
}

type RecordMachineryLogRequest struct {
	Date       string  `json:"date"`
	HoursRun   float64 `json:"hours_run"`
	FuelUsed   float64 `json:"fuel_used"`
	OperatorID uint    `json:"operator_id"`
	Notes      string  `json:"notes"`
}

func RecordMachineryLog(c *fiber.Ctx) error {
	macIDStr := c.Params("id")
	var req RecordMachineryLogRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Date = core.Sanitize(req.Date)
	req.Notes = core.Sanitize(req.Notes)

	if req.Date == "" || req.HoursRun <= 0 {
		return core.SendError(c, fiber.StatusBadRequest, "Date and positive Hours Run are required", nil)
	}

	if !core.IsValidDate(req.Date) {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid date format. Expected YYYY-MM-DD", nil)
	}

	if req.FuelUsed < 0 {
		return core.SendError(c, fiber.StatusBadRequest, "Fuel used cannot be negative", nil)
	}

	tenantID := c.Locals("tenant_id_value").(uint)

	if req.OperatorID != 0 {
		var operator models.LaborWorker
		if err := db.DB.First(&operator, req.OperatorID).Error; err != nil {
			return core.SendError(c, fiber.StatusBadRequest, "Operator not found", err)
		}
		if operator.TenantID != tenantID {
			return core.SendError(c, fiber.StatusForbidden, "Operator does not belong to your tenant", nil)
		}
	}

	tx := db.DB.Begin()

	var mac models.Machinery
	if err := tx.First(&mac, macIDStr).Error; err != nil {
		tx.Rollback()
		return core.SendError(c, fiber.StatusNotFound, "Machinery not found", err)
	}

	if mac.TenantID != tenantID {
		tx.Rollback()
		return core.SendError(c, fiber.StatusForbidden, "Access denied to machinery", nil)
	}

	logEntry := models.MachineryLog{
		TenantID:    &tenantID,
		MachineryID: mac.ID,
		Date:        req.Date,
		UsageHours:  req.HoursRun,
		FuelEntry:   req.FuelUsed,
		LoggedByID:  req.OperatorID,
		Notes:       req.Notes,
	}

	if err := tx.Create(&logEntry).Error; err != nil {
		tx.Rollback()
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to create machinery log", err)
	}

	mac.TotalHoursRun += req.HoursRun
	if err := tx.Save(&mac).Error; err != nil {
		tx.Rollback()
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update machinery total run hours", err)
	}

	tx.Commit()

	return c.Status(fiber.StatusCreated).JSON(logEntry)
}

type UpdateMachineryRequest struct {
	Name        string  `json:"name"`
	ModelNumber string  `json:"model_number"`
	HourlyRate  float64 `json:"hourly_rate"`
	Status      string  `json:"status"` // Active, Maintenance, Idle
}

func UpdateMachinery(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	macID := c.Params("id")

	var mac models.Machinery
	if err := db.DB.First(&mac, macID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Machinery not found", err)
	}
	if mac.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}

	var req UpdateMachineryRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Name = core.Sanitize(req.Name)
	req.ModelNumber = core.Sanitize(req.ModelNumber)
	req.Status = core.Sanitize(req.Status)

	if req.Name != "" {
		mac.Name = req.Name
	}
	if req.ModelNumber != "" {
		mac.ModelNumber = req.ModelNumber
	}
	if req.HourlyRate > 0 {
		mac.HourlyRate = req.HourlyRate
	}
	validStatuses := map[string]bool{"Active": true, "Maintenance": true, "Idle": true}
	if req.Status != "" {
		if !validStatuses[req.Status] {
			return core.SendError(c, fiber.StatusBadRequest, "Invalid status. Use: Active, Maintenance, Idle", nil)
		}
		mac.Status = req.Status
	}

	if err := db.DB.Save(&mac).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update machinery", err)
	}
	return c.JSON(mac)
}

func DeleteMachinery(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	macID := c.Params("id")

	var mac models.Machinery
	if err := db.DB.First(&mac, macID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Machinery not found", err)
	}
	if mac.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}

	if err := db.DB.Delete(&mac).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to delete machinery", err)
	}
	return c.JSON(fiber.Map{"message": "Machinery deleted successfully"})
}
