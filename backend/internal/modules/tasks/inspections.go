package tasks

import (
	"civilos/backend/internal/core"
	"time"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func ListInspections(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	offset, limit := core.GetPagination(c)

	query := db.DB.Where("tenant_id = ?", tenantID)
	query = core.ApplySearch(query, c, "title")

	var total int64
	query.Model(&models.Inspection{}).Count(&total)
	core.SetPaginationHeaders(c, total)

	items := make([]models.Inspection, 0)
	if err := query.Offset(offset).Limit(limit).Order("created_at desc").Find(&items).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch inspections", err)
	}
	return c.JSON(items)
}

type CreateInspectionRequest struct {
	Title       string `json:"title"`
	Description string `json:"description"`
	ProjectID   uint   `json:"project_id"`
	InspectorID uint   `json:"inspector_id"`
	Date        string `json:"date"`
	Status      string `json:"status"`
}

func CreateInspection(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	userID := c.Locals("user_id").(uint)

	var req CreateInspectionRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Title = core.Sanitize(req.Title)
	req.Description = core.Sanitize(req.Description)
	req.Date = core.Sanitize(req.Date)
	req.Status = core.Sanitize(req.Status)

	if req.Title == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Title is required", nil)
	}

	if req.ProjectID != 0 {
		var project models.Project
		if err := db.DB.First(&project, req.ProjectID).Error; err != nil {
			return core.SendError(c, fiber.StatusNotFound, "Project not found", nil)
		}
		if project.TenantID != tenantID {
			return core.SendError(c, fiber.StatusForbidden, "Access denied to project", nil)
		}
	}

	inspection := models.Inspection{
		TenantID:    tenantID,
		ProjectID:   req.ProjectID,
		Title:       req.Title,
		Description: req.Description,
		InspectorID: req.InspectorID,
		Date:        time.Now(),
		Status:      req.Status,
	}

	if inspection.InspectorID == 0 {
		inspection.InspectorID = userID
	}
	if inspection.Status == "" {
		inspection.Status = "Pending"
	}

	if err := db.DB.Create(&inspection).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to create inspection", err)
	}
	return c.Status(fiber.StatusCreated).JSON(inspection)
}

func DeleteInspection(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	id := c.Params("id")
	if err := db.DB.Where("id = ? AND tenant_id = ?", id, tenantID).Delete(&models.Inspection{}).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to delete inspection", err)
	}
	return c.JSON(fiber.Map{"message": "Inspection deleted successfully"})
}

func ListChecklists(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	offset, limit := core.GetPagination(c)

	query := db.DB.Where("tenant_id = ?", tenantID)
	query = core.ApplySearch(query, c, "title", "category")

	var total int64
	query.Model(&models.Checklist{}).Count(&total)
	core.SetPaginationHeaders(c, total)

	items := make([]models.Checklist, 0)
	if err := query.Offset(offset).Limit(limit).Order("created_at desc").Find(&items).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch checklists", err)
	}
	return c.JSON(items)
}

type CreateChecklistRequest struct {
	Title     string `json:"title"`
	Category  string `json:"category"`
	ProjectID uint   `json:"project_id"`
}

func CreateChecklist(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	var req CreateChecklistRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Title = core.Sanitize(req.Title)
	req.Category = core.Sanitize(req.Category)

	if req.Title == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Title is required", nil)
	}

	if req.ProjectID != 0 {
		var project models.Project
		if err := db.DB.First(&project, req.ProjectID).Error; err != nil {
			return core.SendError(c, fiber.StatusNotFound, "Project not found", nil)
		}
		if project.TenantID != tenantID {
			return core.SendError(c, fiber.StatusForbidden, "Access denied to project", nil)
		}
	}

	checklist := models.Checklist{
		TenantID:  tenantID,
		ProjectID: req.ProjectID,
		Title:     req.Title,
		Category:  req.Category,
		Completed: false,
	}

	if err := db.DB.Create(&checklist).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to create checklist", err)
	}
	return c.Status(fiber.StatusCreated).JSON(checklist)
}

func ToggleChecklist(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	id := c.Params("id")

	var item models.Checklist
	if err := db.DB.Where("id = ? AND tenant_id = ?", id, tenantID).First(&item).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Checklist not found", err)
	}

	item.Completed = !item.Completed
	if err := db.DB.Save(&item).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update checklist", err)
	}
	return c.JSON(item)
}

func DeleteChecklist(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	id := c.Params("id")
	if err := db.DB.Where("id = ? AND tenant_id = ?", id, tenantID).Delete(&models.Checklist{}).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to delete checklist", err)
	}
	return c.JSON(fiber.Map{"message": "Checklist deleted successfully"})
}
