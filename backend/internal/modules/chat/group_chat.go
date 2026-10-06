package chat

import (
	"civilos/backend/internal/core"
	"time"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

type SendGroupMessageRequest struct {
	Content string `json:"content"`
}

// GetGroupMessages - Returns last 100 messages in the B2B global chat room
// Accessible to: Contractor + SuperAdmin
func GetGroupMessages(c *fiber.Ctx) error {
	messages := make([]models.GroupMessage, 0)
	if err := db.DB.
		Preload("Sender").
		Preload("Sender.Tenant").
		Order("created_at asc").
		Limit(100).
		Find(&messages).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch group messages", err)
	}
	return c.JSON(messages)
}

// SendGroupMessage - Posts a message to the B2B global chat room
// Accessible to: Contractor + SuperAdmin
func SendGroupMessage(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)

	var req SendGroupMessageRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Content = core.Sanitize(req.Content)

	if req.Content == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Message content cannot be empty", nil)
	}

	msg := models.GroupMessage{
		SenderID:  userID,
		Content:   req.Content,
		CreatedAt: time.Now(),
	}

	if err := db.DB.Create(&msg).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to send message", err)
	}

	// Reload with sender + tenant for the response
	db.DB.Preload("Sender").Preload("Sender.Tenant").First(&msg, msg.ID)

	return c.Status(fiber.StatusCreated).JSON(msg)
}
