package marketplace

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"
	"fmt"

	"github.com/gofiber/fiber/v2"
)

func SupervisorVerifyPO(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	supervisorID := c.Locals("user_id").(uint)
	poID := c.Params("id")

	var po models.PurchaseOrder
	if err := db.DB.Where("id = ? AND tenant_id = ?", poID, tenantID).First(&po).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Purchase order not found", err)
	}

	if po.Status != "Delivered" {
		return core.SendError(c, fiber.StatusConflict, "Can only verify a delivered PO", nil)
	}

	po.Status = "SupervisorVerified"
	if err := db.DB.Save(&po).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update PO status", err)
	}

	supIDStr := fmt.Sprintf("%d", supervisorID)
	tenantStr := fmt.Sprintf("%d", tenantID)
	db.LogAudit(supIDStr, tenantStr, fmt.Sprintf("Supervisor verified PO %s delivery", poID), c.IP())

	return c.JSON(fiber.Map{"message": "PO verified successfully", "po": po})
}

func ContractorConfirmPO(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	contractorID := c.Locals("user_id").(uint)
	poID := c.Params("id")

	var po models.PurchaseOrder
	if err := db.DB.Where("id = ? AND tenant_id = ?", poID, tenantID).First(&po).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Purchase order not found", err)
	}

	if po.Status != "SupervisorVerified" {
		return core.SendError(c, fiber.StatusConflict, "PO must be verified by supervisor first", nil)
	}

	po.Status = "ContractorConfirmed"
	if err := db.DB.Save(&po).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update PO status", err)
	}

	conIDStr := fmt.Sprintf("%d", contractorID)
	tenantStr := fmt.Sprintf("%d", tenantID)
	db.LogAudit(conIDStr, tenantStr, fmt.Sprintf("Contractor confirmed PO %s", poID), c.IP())

	return c.JSON(fiber.Map{"message": "PO confirmed successfully", "po": po})
}

func ContractorCancelPO(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	contractorID := c.Locals("user_id").(uint)
	poID := c.Params("id")

	var po models.PurchaseOrder
	if err := db.DB.Where("id = ? AND tenant_id = ?", poID, tenantID).First(&po).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Purchase order not found", err)
	}

	if po.Status != "Issued" && po.Status != "Accepted" {
		return core.SendError(c, fiber.StatusConflict, "Cannot cancel a PO that is already dispatched or further", nil)
	}

	po.Status = "Cancelled"
	if err := db.DB.Save(&po).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to cancel PO", err)
	}

	conIDStr := fmt.Sprintf("%d", contractorID)
	tenantStr := fmt.Sprintf("%d", tenantID)
	db.LogAudit(conIDStr, tenantStr, fmt.Sprintf("Contractor cancelled PO %s", poID), c.IP())

	return c.JSON(fiber.Map{"message": "PO cancelled successfully", "po": po})
}

func ContractorDuplicatePO(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	contractorID := c.Locals("user_id").(uint)
	poID := c.Params("id")

	var po models.PurchaseOrder
	if err := db.DB.Where("id = ? AND tenant_id = ?", poID, tenantID).First(&po).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Purchase order not found", err)
	}

	newPO := models.PurchaseOrder{
		TenantID:    po.TenantID,
		ItemName:    po.ItemName,
		Quantity:    po.Quantity,
		Unit:        po.Unit,
		UnitPrice:   po.UnitPrice,
		TotalCost:   po.TotalCost,
		ExpectedBy:  po.ExpectedBy,
		ProjectID:   po.ProjectID,
		VendorID:    po.VendorID,
		Status:      "Issued",
		CreatedByID: &contractorID,
	}

	if err := db.DB.Create(&newPO).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to duplicate PO", err)
	}

	return c.JSON(fiber.Map{"message": "PO duplicated successfully", "po": newPO})
}
