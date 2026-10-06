package projects

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

type CreateSiteIssueRequest struct {
	ProjectID   uint   `json:"project_id" validate:"required"`
	Title       string `json:"title" validate:"required"`
	Description string `json:"description"`
	Priority    string `json:"priority"`
	ImageURLs   string `json:"image_urls"` // Mocked URLs
}

func CreateSiteIssue(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	userID := c.Locals("user_id").(uint)

	var req CreateSiteIssueRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request", err)
	}
	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	issue := models.SiteIssue{
		TenantID:    tenantID,
		ProjectID:   req.ProjectID,
		Title:       req.Title,
		Description: req.Description,
		Priority:    req.Priority,
		ReportedBy:  userID,
		ImageURLs:   req.ImageURLs,
	}

	if err := db.DB.Create(&issue).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to create issue", err)
	}

	return c.JSON(fiber.Map{"message": "Issue reported successfully", "issue": issue})
}

func ListSiteIssues(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	projectID := c.Query("project_id")

	query := db.DB.Where("tenant_id = ?", tenantID)
	if projectID != "" {
		query = query.Where("project_id = ?", projectID)
	}

	issues := []models.SiteIssue{}
	if err := query.Find(&issues).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to list issues", err)
	}

	return c.JSON(issues)
}
