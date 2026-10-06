package labor

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func ListWorkers(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	workers := []models.LaborWorker{}
	offset, limit := core.GetPagination(c)

	if err := db.DB.Where("tenant_id = ?", tenantID).Offset(offset).Limit(limit).Find(&workers).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch workers", err)
	}

	return c.JSON(workers)
}

type CreateWorkerRequest struct {
	Name          string  `json:"name"`
	SkillCategory string  `json:"skill_category"`
	DailyRate     float64 `json:"daily_rate"`
}

func CreateWorker(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	var req CreateWorkerRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Name = core.Sanitize(req.Name)
	req.SkillCategory = core.Sanitize(req.SkillCategory)

	if req.Name == "" || req.SkillCategory == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Name and SkillCategory are required", nil)
	}

	if req.DailyRate <= 0 {
		return core.SendError(c, fiber.StatusBadRequest, "Daily rate must be greater than zero", nil)
	}

	worker := models.LaborWorker{
		TenantID:      tenantID,
		Name:          req.Name,
		SkillCategory: req.SkillCategory,
		DailyRate:     req.DailyRate,
	}

	if err := db.DB.Create(&worker).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to register labor worker", err)
	}

	return c.Status(fiber.StatusCreated).JSON(worker)
}

type RecordAttendanceRequest struct {
	LaborWorkerID uint    `json:"labor_worker_id"`
	Date          string  `json:"date"`
	Status        string  `json:"status"`
	OvertimeHours float64 `json:"overtime_hours"`
}

func RecordAttendance(c *fiber.Ctx) error {
	var req RecordAttendanceRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Date = core.Sanitize(req.Date)
	req.Status = core.Sanitize(req.Status)

	if req.LaborWorkerID == 0 || req.Date == "" || req.Status == "" {
		return core.SendError(c, fiber.StatusBadRequest, "WorkerID, Date, and Status are required", nil)
	}

	if !core.IsValidDate(req.Date) {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid date format. Expected YYYY-MM-DD", nil)
	}

	if req.Status != "Present" && req.Status != "Absent" && req.Status != "Overtime" {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid status. Expected Present, Absent, or Overtime", nil)
	}

	if req.OvertimeHours < 0 {
		return core.SendError(c, fiber.StatusBadRequest, "Overtime hours cannot be negative", nil)
	}

	tenantID := c.Locals("tenant_id_value").(uint)

	tx := db.DB.Begin()

	var worker models.LaborWorker
	if err := tx.First(&worker, req.LaborWorkerID).Error; err != nil {
		tx.Rollback()
		return core.SendError(c, fiber.StatusNotFound, "Worker not found", err)
	}

	if worker.TenantID != tenantID {
		tx.Rollback()
		return core.SendError(c, fiber.StatusForbidden, "Access denied to worker attendance", nil)
	}

	month := req.Date[:7]
	var payroll models.PayrollRecord
	err := tx.Where("labor_worker_id = ? AND month = ?", worker.ID, month).First(&payroll).Error

	logs := make([]models.AttendanceLog, 0)
	tx.Where("labor_worker_id = ? AND date LIKE ?", worker.ID, month+"%").Find(&logs)

	var earnings float64
	for _, l := range logs {
		if l.Status == "Present" {
			earnings += worker.DailyRate
		} else if l.Status == "Overtime" {
			hourlyRate := worker.DailyRate / 8.0
			earnings += worker.DailyRate + (l.OvertimeHours * hourlyRate * 1.5)
		}
	}

	if req.Status == "Present" {
		earnings += worker.DailyRate
	} else if req.Status == "Overtime" {
		hourlyRate := worker.DailyRate / 8.0
		earnings += worker.DailyRate + (req.OvertimeHours * hourlyRate * 1.5)
	}

	att := models.AttendanceLog{
		LaborWorkerID: worker.ID,
		Date:          req.Date,
		Status:        req.Status,
		OvertimeHours: req.OvertimeHours,
	}

	if err := tx.Create(&att).Error; err != nil {
		tx.Rollback()
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to record attendance", err)
	}

	if err == nil {
		payroll.WagesEarned = earnings
		if err := tx.Save(&payroll).Error; err != nil {
			tx.Rollback()
			return core.SendError(c, fiber.StatusInternalServerError, "Failed to update payroll wages", err)
		}
	} else {
		payroll = models.PayrollRecord{
			LaborWorkerID: worker.ID,
			Month:         month,
			WagesEarned:   earnings,
			Status:        "Unpaid",
		}
		if err := tx.Create(&payroll).Error; err != nil {
			tx.Rollback()
			return core.SendError(c, fiber.StatusInternalServerError, "Failed to create payroll wages", err)
		}
	}

	tx.Commit()

	return c.Status(fiber.StatusCreated).JSON(att)
}

func ListPayroll(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	payroll := []models.PayrollRecord{}

	if err := db.DB.Joins("JOIN labor_workers ON payroll_records.labor_worker_id = labor_workers.id").
		Where("labor_workers.tenant_id = ?", tenantID).
		Find(&payroll).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch payroll logs", err)
	}

	return c.JSON(payroll)
}

type UpdateWorkerRequest struct {
	Name          string  `json:"name"`
	SkillCategory string  `json:"skill_category"`
	DailyRate     float64 `json:"daily_rate"`
}

func UpdateWorker(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	workerID := c.Params("id")

	var worker models.LaborWorker
	if err := db.DB.First(&worker, workerID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Worker not found", err)
	}
	if worker.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}

	var req UpdateWorkerRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Name = core.Sanitize(req.Name)
	req.SkillCategory = core.Sanitize(req.SkillCategory)

	if req.Name != "" {
		worker.Name = req.Name
	}
	validSkills := map[string]bool{"Mason": true, "Helper": true, "Operator": true, "Carpenter": true, "Electrician": true, "Plumber": true, "Welder": true}
	if req.SkillCategory != "" {
		if !validSkills[req.SkillCategory] {
			return core.SendError(c, fiber.StatusBadRequest, "Invalid skill category", nil)
		}
		worker.SkillCategory = req.SkillCategory
	}
	if req.DailyRate > 0 {
		worker.DailyRate = req.DailyRate
	}

	if err := db.DB.Save(&worker).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update worker", err)
	}
	return c.JSON(worker)
}

func DeleteWorker(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	workerID := c.Params("id")

	var worker models.LaborWorker
	if err := db.DB.First(&worker, workerID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Worker not found", err)
	}
	if worker.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}

	if err := db.DB.Delete(&worker).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to delete worker", err)
	}
	return c.JSON(fiber.Map{"message": "Worker deleted successfully"})
}

func MarkPayrollPaid(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	payrollID := c.Params("id")

	var payroll models.PayrollRecord
	if err := db.DB.First(&payroll, payrollID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Payroll record not found", err)
	}

	// Verify tenant isolation via worker
	var worker models.LaborWorker
	if err := db.DB.First(&worker, payroll.LaborWorkerID).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Worker not found", err)
	}
	if worker.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}

	payroll.Status = "Paid"
	if err := db.DB.Save(&payroll).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to mark payroll as paid", err)
	}
	return c.JSON(payroll)
}
