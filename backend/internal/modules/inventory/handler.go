package inventory

import (
	"fmt"

	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm/clause"
)

func ListInventory(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	items := []models.InventoryItem{}
	offset, limit := core.GetPagination(c)

	if err := db.DB.Where("tenant_id = ?", tenantID).Offset(offset).Limit(limit).Find(&items).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch inventory", err)
	}

	return c.JSON(items)
}

type RecordTransactionRequest struct {
	InventoryItemID  uint    `json:"inventory_item_id" validate:"required"`
	Type             string  `json:"type" validate:"required,oneof=IN OUT"`
	Quantity         float64 `json:"quantity" validate:"required,gt=0"`
	Reference        string  `json:"reference" validate:"omitempty"`
	Notes            string  `json:"notes" validate:"omitempty"`
	TransactionDate  string  `json:"transaction_date" validate:"required"`
	EWayBillNumber   string  `json:"eway_bill_number" validate:"omitempty"`
	EWayBillDocument string  `json:"eway_bill_document" validate:"omitempty"`
}

func RecordTransaction(c *fiber.Ctx) error {
	var req RecordTransactionRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	req.Reference = core.Sanitize(req.Reference)
	req.Notes = core.Sanitize(req.Notes)
	req.TransactionDate = core.Sanitize(req.TransactionDate)

	if !core.IsValidDate(req.TransactionDate) {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid transaction date format. Expected YYYY-MM-DD", nil)
	}

	tenantID := c.Locals("tenant_id_value").(uint)

	tx := db.DB.Begin()

	var item models.InventoryItem
	if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&item, req.InventoryItemID).Error; err != nil {
		tx.Rollback()
		return core.SendError(c, fiber.StatusNotFound, "Inventory item not found", err)
	}

	if item.TenantID != tenantID {
		tx.Rollback()
		return core.SendError(c, fiber.StatusForbidden, "Access denied to inventory item", nil)
	}

	if req.Type == "OUT" && item.Quantity < req.Quantity {
		tx.Rollback()
		return core.SendError(c, fiber.StatusBadRequest, "Insufficient stock levels in warehouse", nil)
	}

	transaction := models.MaterialTransaction{
		InventoryItemID:  item.ID,
		Type:             req.Type,
		Quantity:         req.Quantity,
		Reference:        req.Reference,
		Notes:            req.Notes,
		TransactionDate:  req.TransactionDate,
		EWayBillNumber:   req.EWayBillNumber,
		EWayBillDocument: req.EWayBillDocument,
	}

	if err := tx.Create(&transaction).Error; err != nil {
		tx.Rollback()
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to record transaction", err)
	}

	if req.Type == "IN" {
		item.Quantity += req.Quantity
	} else {
		item.Quantity -= req.Quantity
	}

	if err := tx.Save(&item).Error; err != nil {
		tx.Rollback()
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update item stock quantity", err)
	}

	tx.Commit()

	userID := c.Locals("user_id").(string)
	tenantStr := fmt.Sprintf("%d", tenantID)
	db.LogAudit(userID, tenantStr, fmt.Sprintf("Recorded Inventory Transaction %s for Item %d", req.Type, req.InventoryItemID), c.IP())

	return c.Status(fiber.StatusCreated).JSON(transaction)
}

type CreateInventoryItemRequest struct {
	ItemName    string  `json:"item_name" validate:"required"`
	SKU         string  `json:"sku" validate:"omitempty"`
	Barcode     string  `json:"barcode" validate:"omitempty"`
	Category    string  `json:"category" validate:"omitempty,oneof=Material Equipment Fuel Consumables Tool"`
	Unit        string  `json:"unit" validate:"required"`
	Quantity    float64 `json:"quantity" validate:"omitempty,gte=0"`
	SafetyStock float64 `json:"safety_stock" validate:"omitempty,gte=0"`
}

func CreateInventoryItem(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	var req CreateInventoryItemRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	req.ItemName = core.Sanitize(req.ItemName)
	req.SKU = core.Sanitize(req.SKU)
	req.Barcode = core.Sanitize(req.Barcode)
	req.Category = core.Sanitize(req.Category)
	req.Unit = core.Sanitize(req.Unit)

	item := models.InventoryItem{
		TenantID:    tenantID,
		ItemName:    req.ItemName,
		SKU:         req.SKU,
		Barcode:     req.Barcode,
		Category:    req.Category,
		Unit:        req.Unit,
		Quantity:    req.Quantity,
		SafetyStock: req.SafetyStock,
	}

	if err := db.DB.Create(&item).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to create inventory item", err)
	}

	userID := c.Locals("user_id").(string)
	tenantStr := fmt.Sprintf("%d", tenantID)
	db.LogAudit(userID, tenantStr, "Created Inventory Item: "+item.ItemName, c.IP())

	return c.Status(fiber.StatusCreated).JSON(item)
}

type UpdateInventoryItemRequest struct {
	ItemName    string  `json:"item_name"`
	Category    string  `json:"category"`
	Unit        string  `json:"unit"`
	SafetyStock float64 `json:"safety_stock"`
}

func UpdateInventoryItem(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	itemID := c.Params("id")

	var item models.InventoryItem
	if err := db.DB.First(&item, itemID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Inventory item not found", err)
	}
	if item.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}

	var req UpdateInventoryItemRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.ItemName = core.Sanitize(req.ItemName)
	req.Category = core.Sanitize(req.Category)
	req.Unit = core.Sanitize(req.Unit)

	if req.ItemName != "" {
		item.ItemName = req.ItemName
	}
	if req.Category != "" {
		item.Category = req.Category
	}
	if req.Unit != "" {
		item.Unit = req.Unit
	}
	if req.SafetyStock >= 0 {
		item.SafetyStock = req.SafetyStock
	}

	if err := db.DB.Save(&item).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update inventory item", err)
	}
	return c.JSON(item)
}

func DeleteInventoryItem(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	itemID := c.Params("id")

	var item models.InventoryItem
	if err := db.DB.First(&item, itemID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Inventory item not found", err)
	}
	if item.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}

	if err := db.DB.Delete(&item).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to delete inventory item", err)
	}
	return c.JSON(fiber.Map{"message": "Inventory item deleted"})
}
