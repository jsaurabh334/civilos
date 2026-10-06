package tasks

import (
	"civilos/backend/internal/modules/notifications"

	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func ListWorkOrders(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	orders := []models.WorkOrder{}
	offset, limit := core.GetPagination(c)

	query := db.DB.Where("tenant_id = ?", tenantID)

	if projectID := c.QueryInt("project_id", 0); projectID > 0 {
		var project models.Project
		if err := db.DB.First(&project, projectID).Error; err != nil {
			return core.SendError(c, fiber.StatusNotFound, "Project not found", nil)
		}
		if project.TenantID != tenantID {
			return core.SendError(c, fiber.StatusForbidden, "Access denied to project", nil)
		}
		query = query.Where("project_id = ?", projectID)
	}

	query = core.ApplySearch(query, c, "title", "description", "assigned_to")

	var total int64
	query.Model(&models.WorkOrder{}).Count(&total)
	core.SetPaginationHeaders(c, total)

	if err := query.Order("created_at desc").Offset(offset).Limit(limit).Find(&orders).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch work orders", err)
	}
	return c.JSON(orders)
}

type CreateWorkOrderRequest struct {
	Title       string `json:"title"`
	Description string `json:"description"`
	ProjectID   uint   `json:"project_id"`
	AssignedTo  string `json:"assigned_to"`
	DueDate     string `json:"due_date"`
	Priority    string `json:"priority"`
}

func CreateWorkOrder(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	var req CreateWorkOrderRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Title = core.Sanitize(req.Title)
	req.Description = core.Sanitize(req.Description)
	req.AssignedTo = core.Sanitize(req.AssignedTo)
	req.DueDate = core.Sanitize(req.DueDate)
	req.Priority = core.Sanitize(req.Priority)

	if req.Title == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Title is required", nil)
	}
	if req.DueDate != "" && !core.IsValidDate(req.DueDate) {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid due date format. Expected YYYY-MM-DD", nil)
	}
	if req.Priority != "" && !core.IsValidPriority(req.Priority) {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid priority. Use: Low, Medium, High, Critical", nil)
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

	if req.Priority == "" {
		req.Priority = "Medium"
	}

	wo := models.WorkOrder{
		TenantID:    tenantID,
		Title:       req.Title,
		Description: req.Description,
		ProjectID:   req.ProjectID,
		AssignedTo:  req.AssignedTo,
		DueDate:     req.DueDate,
		Priority:    req.Priority,
		Status:      "Open",
	}

	if err := db.DB.Create(&wo).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to create work order", err)
	}

	notifications.NotifyWorkOrderAssigned(wo)

	return c.Status(fiber.StatusCreated).JSON(wo)
}

func UpdateWorkOrderStatus(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	woID := c.Params("id")

	var wo models.WorkOrder
	if err := db.DB.First(&wo, woID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Work order not found", err)
	}
	if wo.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}

	var body struct {
		Status string `json:"status"`
	}
	if err := c.BodyParser(&body); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request", err)
	}

	if !core.IsValidWorkOrderStatus(body.Status) {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid status. Use: Open, InProgress, Completed, Cancelled", nil)
	}

	wo.Status = body.Status
	if err := db.DB.Save(&wo).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update work order", err)
	}
	return c.JSON(wo)
}

func DeleteWorkOrder(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	id := c.Params("id")

	var wo models.WorkOrder
	if err := db.DB.Where("id = ? AND tenant_id = ?", id, tenantID).First(&wo).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Work order not found", err)
	}

	if err := db.DB.Delete(&wo).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to delete work order", err)
	}
	return c.JSON(fiber.Map{"message": "Work order deleted successfully"})
}
