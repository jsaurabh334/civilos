package chat

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/modules/auth"
	"encoding/json"
	"time"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"
	"civilos/backend/internal/ws"

	"github.com/gofiber/fiber/v2"
)

type SendMessageRequest struct {
	ReceiverID uint   `json:"receiver_id"`
	Content    string `json:"content"`
}

func SendMessage(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	userTenantID := c.Locals("tenant_id_value").(uint)
	var req SendMessageRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Content = core.Sanitize(req.Content)

	if req.ReceiverID == 0 || req.Content == "" {
		return core.SendError(c, fiber.StatusBadRequest, "ReceiverID and Content are required", nil)
	}

	if req.ReceiverID == userID {
		return core.SendError(c, fiber.StatusBadRequest, "Cannot send message to yourself", nil)
	}

	var receiver models.User
	if err := db.DB.First(&receiver, req.ReceiverID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Receiver not found", err)
	}

	if receiver.TenantID != nil && *receiver.TenantID != userTenantID && userTenantID != 0 {
		return core.SendError(c, fiber.StatusForbidden, "Cannot message users outside your tenant", nil)
	}

	msg := models.Message{
		SenderID:   userID,
		ReceiverID: req.ReceiverID,
		Content:    req.Content,
		CreatedAt:  time.Now(),
	}

	if err := db.DB.Create(&msg).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to send message", err)
	}

	// Broadcast via WebSocket to receiver
	msgJSON, _ := json.Marshal(msg)
	ws.GlobalHub.SendToUser(req.ReceiverID, msgJSON)

	// Also broadcast to sender's other sessions (e.g., multiple tabs)
	ws.GlobalHub.SendToUser(userID, msgJSON)

	// Trigger FCM push notification to receiver
	if receiver.FCMToken != "" {
		auth.FCM.SendPushNotification(receiver.ID, receiver.FCMToken, "New Chat Message", "You have received a new message.")
	}

	return c.Status(fiber.StatusCreated).JSON(msg)
}

func ListMessages(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	receiverID := c.Params("receiverId")
	offset, limit := core.GetPagination(c)

	messages := []models.Message{}
	if err := db.DB.Preload("Sender").Preload("Receiver").
		Where("(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)", userID, receiverID, receiverID, userID).
		Order("created_at asc").
		Offset(offset).Limit(limit).
		Find(&messages).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch messages", err)
	}

	return c.JSON(messages)
}
