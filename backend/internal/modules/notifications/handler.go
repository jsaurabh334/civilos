package notifications

import (
	"civilos/backend/internal/core"
	"strconv"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func ListNotifications(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	offset, limit := core.GetPagination(c)

	notifications := make([]models.Notification, 0)
	if err := db.DB.Where("user_id = ?", userID).
		Order("created_at DESC").
		Offset(offset).Limit(limit).
		Find(&notifications).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch notifications", err)
	}

	var unreadCount int64
	db.DB.Model(&models.Notification{}).Where("user_id = ? AND read = ?", userID, false).Count(&unreadCount)

	return c.JSON(fiber.Map{
		"notifications": notifications,
		"unread_count":  unreadCount,
	})
}

func MarkNotificationRead(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	idParam := c.Params("id")

	if idParam == "all" {
		if err := db.DB.Model(&models.Notification{}).
			Where("user_id = ? AND read = ?", userID, false).
			Update("read", true).Error; err != nil {
			return core.SendError(c, fiber.StatusInternalServerError, "Failed to mark all as read", err)
		}
		return c.JSON(fiber.Map{"message": "All notifications marked as read"})
	}

	id, err := strconv.ParseUint(idParam, 10, 64)
	if err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid notification ID", err)
	}

	result := db.DB.Model(&models.Notification{}).
		Where("id = ? AND user_id = ?", id, userID).
		Update("read", true)
	if result.Error != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to mark notification as read", err)
	}
	if result.RowsAffected == 0 {
		return core.SendError(c, fiber.StatusNotFound, "Notification not found", nil)
	}

	return c.JSON(fiber.Map{"message": "Notification marked as read"})
}

func DeleteNotification(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	idParam := c.Params("id")

	if idParam == "all" {
		if err := db.DB.Where("user_id = ?", userID).Delete(&models.Notification{}).Error; err != nil {
			return core.SendError(c, fiber.StatusInternalServerError, "Failed to clear notifications", err)
		}
		return c.JSON(fiber.Map{"message": "All notifications cleared"})
	}

	id, err := strconv.ParseUint(idParam, 10, 64)
	if err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid notification ID", err)
	}

	result := db.DB.Where("id = ? AND user_id = ?", id, userID).Delete(&models.Notification{})
	if result.Error != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to delete notification", err)
	}
	if result.RowsAffected == 0 {
		return core.SendError(c, fiber.StatusNotFound, "Notification not found", nil)
	}

	return c.JSON(fiber.Map{"message": "Notification deleted"})
}
