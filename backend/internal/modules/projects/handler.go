package projects

import (
	"fmt"
	"time"

	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func GetProject(c *fiber.Ctx) error {
	projectID := c.Params("projectId")
	role := c.Locals("role").(string)

	var project models.Project

	if role == "SuperAdmin" {
		if err := db.DB.Preload("BOQItems").First(&project, projectID).Error; err != nil {
			return core.SendError(c, fiber.StatusNotFound, "Project not found", err)
		}
	} else {
		tenantID := c.Locals("tenant_id_value").(uint)
		query := db.DB.Preload("BOQItems").Where("projects.id = ? AND projects.tenant_id = ?", projectID, tenantID)

		if role == "Supervisor" {
			userID := c.Locals("user_id").(uint)
			now := time.Now().Format("2006-01-02")
			query = query.Joins("JOIN project_assignments ON project_assignments.project_id = projects.id").
				Where("project_assignments.user_id = ? AND project_assignments.deleted_at IS NULL", userID).
				Where("(project_assignments.start_date IS NULL OR project_assignments.start_date <= ?) AND (project_assignments.end_date IS NULL OR project_assignments.end_date >= ?)", now, now)
		}

		if err := query.First(&project).Error; err != nil {
			return core.SendError(c, fiber.StatusNotFound, "Project not found or access denied", err)
		}
	}

	if project.BOQItems == nil {
		project.BOQItems = []models.BOQItem{}
	}

	return c.JSON(project)
}

func ListProjects(c *fiber.Ctx) error {
	role := c.Locals("role").(string)

	// Initialize empty slice to avoid null arrays in JSON output
	projects := []models.Project{}

	limit := c.QueryInt("limit", 50)
	page := c.QueryInt("page", 1)
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	if page <= 0 {
		page = 1
	}
	offset := (page - 1) * limit

	if role == "SuperAdmin" {
		// SuperAdmin sees everything, option to filter by tenant_id
		tenantIDFilter := c.QueryInt("tenant_id", 0)
		query := db.DB.Preload("BOQItems").Offset(offset).Limit(limit)
		if tenantIDFilter > 0 {
			query = query.Where("tenant_id = ?", tenantIDFilter)
		}
		if err := query.Find(&projects).Error; err != nil {
			return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch projects", err)
		}
	} else {
		// Enforce tenant isolation
		tenantID := c.Locals("tenant_id_value").(uint)
		query := db.DB.Preload("BOQItems").Where("tenant_id = ?", tenantID).Offset(offset).Limit(limit)

		if role == "Supervisor" {
			userID := c.Locals("user_id").(uint)
			now := time.Now().Format("2006-01-02")
			query = query.Joins("JOIN project_assignments ON project_assignments.project_id = projects.id").
				Where("project_assignments.user_id = ? AND project_assignments.deleted_at IS NULL", userID).
				Where("(project_assignments.start_date IS NULL OR project_assignments.start_date <= ?) AND (project_assignments.end_date IS NULL OR project_assignments.end_date >= ?)", now, now)
		}

		if err := query.Find(&projects).Error; err != nil {
			return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch projects", err)
		}
	}

	// Fix Bug 9: Iterate and initialize any preloaded nil BOQItems slices to avoid "null" array serialization
	for i := range projects {
		if projects[i].BOQItems == nil {
			projects[i].BOQItems = []models.BOQItem{}
		}
	}

	return c.JSON(projects)
}

type CreateProjectRequest struct {
	Name          string           `json:"name" validate:"required"`
	Description   string           `json:"description" validate:"omitempty"`
	Location      string           `json:"location" validate:"required"`
	ProjectType   string           `json:"project_type" validate:"omitempty"`
	TenderNo      string           `json:"tender_no" validate:"omitempty"`
	TenderDetails string           `json:"tender_details" validate:"omitempty"`
	BOQItems      []models.BOQItem `json:"boq_items" validate:"dive"`
}

func CreateProject(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	var req CreateProjectRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	req.Name = core.Sanitize(req.Name)
	req.Description = core.Sanitize(req.Description)
	req.Location = core.Sanitize(req.Location)
	req.ProjectType = core.Sanitize(req.ProjectType)
	req.TenderNo = core.Sanitize(req.TenderNo)
	req.TenderDetails = core.Sanitize(req.TenderDetails)

	if req.Name == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Project name is required", nil)
	}
	if req.Location == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Project location is required", nil)
	}
	if req.ProjectType == "" {
		req.ProjectType = "Private" // default to Private
	}

	// Initialize empty slice for BOQItems if nil
	if req.BOQItems == nil {
		req.BOQItems = []models.BOQItem{}
	}

	// Validate against negative/zero quantities and rates
	for i := range req.BOQItems {
		req.BOQItems[i].Description = core.Sanitize(req.BOQItems[i].Description)
		req.BOQItems[i].Unit = core.Sanitize(req.BOQItems[i].Unit)
		if req.BOQItems[i].Description == "" || req.BOQItems[i].Unit == "" {
			return core.SendError(c, fiber.StatusBadRequest, "BOQ Item description and unit are required", nil)
		}
		if req.BOQItems[i].PlannedQuantity <= 0 || req.BOQItems[i].Rate <= 0 {
			return core.SendError(c, fiber.StatusBadRequest, "BOQ Item planned quantity and rate must be greater than zero", nil)
		}
	}

	project := models.Project{
		Name:          req.Name,
		Description:   req.Description,
		Location:      req.Location,
		ProjectType:   req.ProjectType,
		TenderNo:      req.TenderNo,
		TenderDetails: req.TenderDetails,
		TenantID:      tenantID,
		BOQItems:      req.BOQItems,
	}

	if err := db.DB.Create(&project).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to create project", err)
	}

	userID := fmt.Sprintf("%d", c.Locals("user_id").(uint))
	tenantStr := fmt.Sprintf("%d", tenantID)
	db.LogAudit(userID, tenantStr, "Created Project", c.IP())

	return c.Status(fiber.StatusCreated).JSON(project)
}

type UpdateProjectRequest struct {
	Name        string `json:"name" validate:"omitempty"`
	Description string `json:"description" validate:"omitempty"`
	Location    string `json:"location" validate:"omitempty"`
	Status      string `json:"status" validate:"omitempty,oneof=Planning Active OnHold Completed"`
}

func UpdateProject(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	projectID := c.Params("projectId")

	var project models.Project
	if err := db.DB.First(&project, projectID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Project not found", err)
	}
	if project.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}

	var req UpdateProjectRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	req.Name = core.Sanitize(req.Name)
	req.Description = core.Sanitize(req.Description)
	req.Location = core.Sanitize(req.Location)
	req.Status = core.Sanitize(req.Status)

	if req.Name != "" {
		project.Name = req.Name
	}
	if req.Description != "" {
		project.Description = req.Description
	}
	if req.Location != "" {
		project.Location = req.Location
	}

	if err := db.DB.Save(&project).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update project", err)
	}
	db.DB.Preload("BOQItems").First(&project, project.ID)
	if project.BOQItems == nil {
		project.BOQItems = []models.BOQItem{}
	}

	userID := fmt.Sprintf("%d", c.Locals("user_id").(uint))
	tenantStr := fmt.Sprintf("%d", tenantID)
	db.LogAudit(userID, tenantStr, "Updated Project: "+projectID, c.IP())

	return c.JSON(project)
}

func DeleteProject(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	projectID := c.Params("projectId")

	var project models.Project
	if err := db.DB.First(&project, projectID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Project not found", err)
	}
	if project.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}

	if err := db.DB.Delete(&project).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to delete project", err)
	}
	return c.JSON(fiber.Map{"message": "Project deleted successfully"})
}

type ImportBOQRequest struct {
	Items []models.BOQItem `json:"items"`
}

func ImportBOQ(c *fiber.Ctx) error {
	projectIDStr := c.Params("projectId")
	var req ImportBOQRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	var project models.Project
	if err := db.DB.First(&project, projectIDStr).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Project not found", err)
	}

	tenantID := c.Locals("tenant_id_value").(uint)
	if project.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied to project BOQ", nil)
	}

	tx := db.DB.Begin()
	for i := range req.Items {
		req.Items[i].ProjectID = project.ID
		req.Items[i].Description = core.Sanitize(req.Items[i].Description)
		req.Items[i].Unit = core.Sanitize(req.Items[i].Unit)
		if req.Items[i].Description == "" || req.Items[i].Unit == "" {
			tx.Rollback()
			return core.SendError(c, fiber.StatusBadRequest, "Description and unit are required for all BOQ items", nil)
		}
		if req.Items[i].PlannedQuantity <= 0 || req.Items[i].Rate <= 0 {
			tx.Rollback()
			return core.SendError(c, fiber.StatusBadRequest, "Planned quantity and rate must be greater than zero", nil)
		}
		if err := tx.Create(&req.Items[i]).Error; err != nil {
			tx.Rollback()
			return core.SendError(c, fiber.StatusInternalServerError, "Failed to import BOQ item", err)
		}
	}
	tx.Commit()

	db.DB.Preload("BOQItems").First(&project, project.ID)

	if project.BOQItems == nil {
		project.BOQItems = []models.BOQItem{}
	}

	return c.JSON(project)
}

func GetProjectStats(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	projectId := c.Params("projectId")

	var project models.Project
	if err := db.DB.Where("id = ? AND tenant_id = ?", projectId, tenantID).First(&project).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Project not found", err)
	}

	// Expenses for this project
	var totalExpenses float64
	db.DB.Model(&models.Expense{}).Where("project_id = ?", projectId).Select("COALESCE(SUM(amount), 0)").Scan(&totalExpenses)

	// Invoices for this project
	var totalInvoiced float64
	db.DB.Model(&models.Invoice{}).Where("project_id = ?", projectId).Select("COALESCE(SUM(total_amount), 0)").Scan(&totalInvoiced)

	// Tasks / Work Orders for this project
	var totalTasks int64
	db.DB.Model(&models.WorkOrder{}).Where("project_id = ?", projectId).Count(&totalTasks)

	var completedTasks int64
	db.DB.Model(&models.WorkOrder{}).Where("project_id = ? AND status = ?", projectId, "Completed").Count(&completedTasks)

	// Attendance / Labor today for this project (requires joining labor_workers to projects, or we can just count total workers present across tenant since attendance is often site-wide, but let's assume attendance doesn't have project_id right now. Let's return what we have).

	return c.JSON(fiber.Map{
		"total_expenses":  totalExpenses,
		"total_invoiced":  totalInvoiced,
		"total_tasks":     totalTasks,
		"completed_tasks": completedTasks,
	})
}
