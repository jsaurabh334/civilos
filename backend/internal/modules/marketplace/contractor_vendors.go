package marketplace

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

// ListAllPlatformVendors lists all vendors on the platform for the contractor to search
func ListAllPlatformVendors(c *fiber.Ctx) error {
	vendors := []models.User{}
	offset, limit := core.GetPagination(c)
	if err := db.DB.Where("role = ? AND verification_status = ?", "Vendor", "Verified").Offset(offset).Limit(limit).Find(&vendors).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch vendors", err)
	}

	return c.JSON(vendors)
}

// GetContractorVendors lists vendors the contractor has interacted with (relations)
func GetContractorVendors(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	relations := []models.ContractorVendorRelation{}
	offset, limit := core.GetPagination(c)
	if err := db.DB.Preload("Vendor").Where("tenant_id = ?", tenantID).Offset(offset).Limit(limit).Find(&relations).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch contractor vendors", err)
	}

	return c.JSON(relations)
}

type UpdateVendorRelationRequest struct {
	IsFavorite *bool `json:"is_favorite"`
	IsBlocked  *bool `json:"is_blocked"`
	Rating     *int  `json:"rating" validate:"omitempty,min=1,max=5"`
}

// UpdateVendorRelation updates favorite, block, or rating status
func UpdateVendorRelation(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	vendorID := c.Params("vendorId")

	var req UpdateVendorRelationRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	var relation models.ContractorVendorRelation
	err := db.DB.Where("tenant_id = ? AND vendor_id = ?", tenantID, vendorID).First(&relation).Error
	if err != nil {
		// Create new relation
		var vID uint
		// Convert vendorID string to uint
		// We can just rely on the DB to cast or do a subquery, but let's fetch the vendor first to be safe
		var vendor models.User
		if err := db.DB.First(&vendor, vendorID).Error; err != nil {
			return core.SendError(c, fiber.StatusNotFound, "Vendor not found", err)
		}
		vID = vendor.ID

		relation = models.ContractorVendorRelation{
			TenantID: tenantID,
			VendorID: vID,
		}
	}

	if req.IsFavorite != nil {
		relation.IsFavorite = *req.IsFavorite
	}
	if req.IsBlocked != nil {
		relation.IsBlocked = *req.IsBlocked
	}
	if req.Rating != nil {
		relation.Rating = *req.Rating
	}

	if err := db.DB.Save(&relation).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update vendor relation", err)
	}

	return c.JSON(fiber.Map{"message": "Vendor relation updated successfully", "relation": relation})
}
