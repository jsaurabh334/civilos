package marketplace

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"
	"fmt"

	"github.com/gofiber/fiber/v2"
)

func ListVendorPOs(c *fiber.Ctx) error {
	vendorID := c.Locals("user_id").(uint)
	tenantID := c.Locals("tenant_id_value").(uint)

	pos := []models.PurchaseOrder{}

	offset, limit := core.GetPagination(c)
	if err := db.DB.Where("tenant_id = ? AND vendor_id = ?", tenantID, vendorID).
		Offset(offset).Limit(limit).Find(&pos).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch purchase orders", err)
	}

	return c.JSON(pos)
}

type UpdatePOStatusRequest struct {
	Status string `json:"status" validate:"required,oneof=Accepted Rejected Dispatched"`
}

func UpdatePOStatus(c *fiber.Ctx) error {
	vendorID := c.Locals("user_id").(uint)
	tenantID := c.Locals("tenant_id_value").(uint)
	poID := c.Params("id")

	var req UpdatePOStatusRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	var po models.PurchaseOrder
	if err := db.DB.Where("id = ? AND tenant_id = ? AND vendor_id = ?", poID, tenantID, vendorID).First(&po).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Purchase order not found", err)
	}

	po.Status = req.Status
	if err := db.DB.Save(&po).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update PO status", err)
	}

	vendorIDStr := fmt.Sprintf("%d", vendorID)
	tenantStr := fmt.Sprintf("%d", tenantID)
	db.LogAudit(vendorIDStr, tenantStr, "Vendor updated PO status to "+req.Status, c.IP())

	return c.JSON(po)
}

type SubmitInvoiceRequest struct {
	Amount float64 `json:"amount" validate:"required,gt=0"`
	Notes  string  `json:"notes" validate:"omitempty"`
}

func SubmitInvoice(c *fiber.Ctx) error {
	vendorID := c.Locals("user_id").(uint)
	tenantID := c.Locals("tenant_id_value").(uint)
	poID := c.Params("id")

	var req SubmitInvoiceRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	var po models.PurchaseOrder
	if err := db.DB.Where("id = ? AND tenant_id = ? AND vendor_id = ?", poID, tenantID, vendorID).First(&po).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Purchase order not found", err)
	}

	if po.Status != "Dispatched" && po.Status != "Accepted" {
		return core.SendError(c, fiber.StatusConflict, "Cannot invoice a PO that is not accepted or dispatched", nil)
	}

	// Update PO Status
	po.Status = "Invoiced"
	if err := db.DB.Save(&po).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update PO status to Invoiced", err)
	}

	// In a complete implementation, this would also create a record in the 'invoices' table.
	// We'll simulate this by just auditing it for now.
	vendorIDStr := fmt.Sprintf("%d", vendorID)
	tenantStr := fmt.Sprintf("%d", tenantID)
	db.LogAudit(vendorIDStr, tenantStr, fmt.Sprintf("Vendor submitted invoice for PO %s", poID), c.IP())

	return c.JSON(fiber.Map{"message": "Invoice submitted successfully", "po": po})
}
