package projects

import (
	"civilos/backend/internal/modules/notifications"

	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func ListDiaries(c *fiber.Ctx) error {
	projectID := c.Params("projectId")
	role := c.Locals("role").(string)
	offset, limit := core.GetPagination(c)

	var project models.Project
	if err := db.DB.First(&project, projectID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Project not found", err)
	}

	if role != "SuperAdmin" {
		tenantID := c.Locals("tenant_id_value").(uint)
		if project.TenantID != tenantID {
			return core.SendError(c, fiber.StatusForbidden, "Access denied to project details", nil)
		}
	}

	base := db.DB.Where("project_id = ?", projectID)
	base = core.ApplySearch(base, c, "completed_work", "weather")

	var total int64
	base.Model(&models.DailyDiaryEntry{}).Count(&total)
	core.SetPaginationHeaders(c, total)

	diaries := []models.DailyDiaryEntry{}
	if err := base.Preload("Supervisor").Offset(offset).Limit(limit).Order("created_at desc").Find(&diaries).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch diary entries", err)
	}

	return c.JSON(diaries)
}

type SubmitDiaryRequest struct {
	Date          string `json:"date"` // YYYY-MM-DD
	Weather       string `json:"weather"`
	LaborStrength int    `json:"labor_strength"`
	CompletedWork string `json:"completed_work"`
}

func SubmitDiary(c *fiber.Ctx) error {
	projectID := c.Params("projectId")
	userID := c.Locals("user_id").(uint)
	role := c.Locals("role").(string)

	var project models.Project
	if err := db.DB.First(&project, projectID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Project not found", err)
	}

	// Enforce tenant isolation
	if role != "SuperAdmin" {
		tenantID := c.Locals("tenant_id_value").(uint)
		if project.TenantID != tenantID {
			return core.SendError(c, fiber.StatusForbidden, "Access denied to project", nil)
		}
	}

	var req SubmitDiaryRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Date = core.Sanitize(req.Date)
	req.Weather = core.Sanitize(req.Weather)
	req.CompletedWork = core.Sanitize(req.CompletedWork)

	if req.Date == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Date is required", nil)
	}
	if !core.IsValidDate(req.Date) {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid date format. Expected YYYY-MM-DD", nil)
	}

	if req.LaborStrength < 0 {
		return core.SendError(c, fiber.StatusBadRequest, "Labor strength cannot be negative", nil)
	}

	diary := models.DailyDiaryEntry{
		ProjectID:     project.ID,
		SupervisorID:  userID,
		Date:          req.Date,
		Weather:       req.Weather,
		LaborStrength: req.LaborStrength,
		CompletedWork: req.CompletedWork,
	}

	if err := db.DB.Create(&diary).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to submit daily diary entry", err)
	}

	// Load relationships for return response
	db.DB.Preload("Supervisor").First(&diary, diary.ID)

	return c.Status(fiber.StatusCreated).JSON(diary)
}

func ApproveDiary(c *fiber.Ctx) error {
	diaryID := c.Params("id")
	var diary models.DailyDiaryEntry
	if err := db.DB.First(&diary, diaryID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Diary entry not found", err)
	}

	var project models.Project
	if err := db.DB.First(&project, diary.ProjectID).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to retrieve diary project", err)
	}

	tenantID := c.Locals("tenant_id_value").(uint)
	if project.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied to diary entry", nil)
	}

	diary.Approved = true
	if err := db.DB.Save(&diary).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to approve diary", err)
	}

	// Send notification
	engineerName := ""
	if diary.SupervisorID != 0 {
		var eng models.User
		if err := db.DB.First(&eng, diary.SupervisorID).Error; err == nil {
			engineerName = eng.Name
		}
	}
	notifications.NotifyDiaryApproved(diary.ID, diary.ProjectID, engineerName)

	return c.JSON(diary)
}

type UpdateDiaryRequest struct {
	Weather       string `json:"weather"`
	LaborStrength int    `json:"labor_strength"`
	CompletedWork string `json:"completed_work"`
	ImageURLs     string `json:"image_urls"`
}

func UpdateDiary(c *fiber.Ctx) error {
	diaryID := c.Params("id")
	tenantID := c.Locals("tenant_id_value").(uint)

	var diary models.DailyDiaryEntry
	if err := db.DB.First(&diary, diaryID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Diary entry not found", err)
	}

	var project models.Project
	if err := db.DB.First(&project, diary.ProjectID).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to verify project", err)
	}
	if project.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}

	if diary.Approved {
		return core.SendError(c, fiber.StatusBadRequest, "Cannot edit an approved diary entry", nil)
	}

	var req UpdateDiaryRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Weather = core.Sanitize(req.Weather)
	req.CompletedWork = core.Sanitize(req.CompletedWork)
	req.ImageURLs = core.Sanitize(req.ImageURLs)

	if req.Weather != "" {
		diary.Weather = req.Weather
	}
	if req.LaborStrength > 0 {
		diary.LaborStrength = req.LaborStrength
	}
	if req.CompletedWork != "" {
		diary.CompletedWork = req.CompletedWork
	}
	if req.ImageURLs != "" {
		diary.ImageURLs = req.ImageURLs
	}

	if err := db.DB.Save(&diary).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update diary entry", err)
	}
	return c.JSON(diary)
}

func DeleteDiary(c *fiber.Ctx) error {
	diaryID := c.Params("id")
	tenantID := c.Locals("tenant_id_value").(uint)

	var diary models.DailyDiaryEntry
	if err := db.DB.First(&diary, diaryID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Diary entry not found", err)
	}

	var project models.Project
	if err := db.DB.First(&project, diary.ProjectID).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to verify project", err)
	}
	if project.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}

	if diary.Approved {
		return core.SendError(c, fiber.StatusBadRequest, "Cannot delete an approved diary entry", nil)
	}

	if err := db.DB.Delete(&diary).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to delete diary entry", err)
	}
	return c.JSON(fiber.Map{"message": "Diary entry deleted successfully"})
}
