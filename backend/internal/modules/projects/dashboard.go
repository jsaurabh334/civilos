package projects

import (
	"fmt"
	"time"

	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func GetDashboardStats(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	projectID := c.QueryInt("project_id", 0)

	if projectID > 0 {
		var project models.Project
		if err := db.DB.First(&project, projectID).Error; err != nil {
			return core.SendError(c, fiber.StatusNotFound, "Project not found", nil)
		}
		if project.TenantID != tenantID {
			return core.SendError(c, fiber.StatusForbidden, "Access denied to project", nil)
		}
	}

	cacheKey := fmt.Sprintf("dashboard_stats_%d", tenantID)
	var cachedStats map[string]interface{}
	if err := core.GetCache(cacheKey, &cachedStats); err == nil {
		return c.JSON(cachedStats)
	}

	svc := DashboardService{}
	stats := svc.GetStats(tenantID)

	core.SetCache(cacheKey, stats, 5*time.Minute)

	return c.JSON(stats)
}
