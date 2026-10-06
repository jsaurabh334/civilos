package admin

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func ListGlobalVendors(c *fiber.Ctx) error {
	page := c.QueryInt("page", 1)
	limit := c.QueryInt("limit", 20)
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	vendors := []models.User{}
	var total int64

	db.DB.Model(&models.User{}).Where("role = ?", "Vendor").Count(&total)

	if err := db.DB.Where("role = ?", "Vendor").Offset(offset).Limit(limit).Order("created_at desc").Find(&vendors).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch vendors", err)
	}

	return c.JSON(fiber.Map{
		"data":  vendors,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

type SetVendorStatusRequest struct {
	VerificationStatus string `json:"verification_status" validate:"required,oneof=Pending Verified Suspended Blacklisted"`
}

func SetVendorVerificationStatus(c *fiber.Ctx) error {
	vendorID := c.Params("id")
	var req SetVendorStatusRequest

	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	var vendor models.User
	if err := db.DB.Where("id = ? AND role = ?", vendorID, "Vendor").First(&vendor).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Vendor not found", err)
	}

	vendor.VerificationStatus = req.VerificationStatus
	if err := db.DB.Save(&vendor).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update vendor status", err)
	}

	db.LogAudit("SuperAdmin", "Global", "Updated vendor "+vendorID+" status to "+req.VerificationStatus, c.IP())

	return c.JSON(vendor)
}
