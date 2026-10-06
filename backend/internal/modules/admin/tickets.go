package admin

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

type CreateTicketRequest struct {
	Subject     string `json:"subject"`
	Description string `json:"description"`
	Priority    string `json:"priority"`
}

func CreateTicket(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	userID := c.Locals("user_id").(uint)

	var req CreateTicketRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	ticket := models.SupportTicket{
		TenantID:    tenantID,
		UserID:      userID,
		Subject:     req.Subject,
		Description: req.Description,
		Priority:    req.Priority,
		Status:      "Open",
	}

	if err := db.DB.Create(&ticket).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to create ticket", err)
	}

	return c.Status(fiber.StatusCreated).JSON(ticket)
}

func ListMyTickets(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	tickets := make([]models.SupportTicket, 0)
	offset, limit := core.GetPagination(c)

	if err := db.DB.Where("tenant_id = ?", tenantID).Order("created_at desc").Offset(offset).Limit(limit).Find(&tickets).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch tickets", err)
	}

	return c.JSON(tickets)
}

func ListAllTickets(c *fiber.Ctx) error {
	tickets := make([]models.SupportTicket, 0)
	offset, limit := core.GetPagination(c)
	if err := db.DB.Order("created_at desc").Offset(offset).Limit(limit).Find(&tickets).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch all tickets", err)
	}
	return c.JSON(tickets)
}
