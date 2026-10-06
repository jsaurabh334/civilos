package admin

import (
	"fmt"

	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

// GetMyAuditLogs returns audit log entries for the currently authenticated user
func GetMyAuditLogs(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	offset, limit := core.GetPagination(c)

	logs := []models.SystemAuditLog{}
	if err := db.DB.Where("actor = ?", fmt.Sprintf("%d", userID)).
		Order("created_at desc").
		Offset(offset).Limit(limit).
		Find(&logs).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch audit logs", err)
	}

	return c.JSON(fiber.Map{
		"logs":  logs,
		"total": len(logs),
	})
}
