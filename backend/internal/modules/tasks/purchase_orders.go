package tasks

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func ListPurchaseOrders(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	orders := []models.PurchaseOrder{}
	offset, limit := core.GetPagination(c)

	query := db.DB.Where("tenant_id = ?", tenantID)

	if projectID := c.QueryInt("project_id", 0); projectID > 0 {
		query = query.Where("project_id = ?", projectID)
	}

	if err := query.Order("order_date desc").Offset(offset).Limit(limit).Find(&orders).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch purchase orders", err)
	}
	return c.JSON(orders)
}

type CreatePurchaseOrderRequest struct {
	VendorName string  `json:"vendor_name"`
	ItemName   string  `json:"item_name"`
	Quantity   float64 `json:"quantity"`
	Unit       string  `json:"unit"`
	UnitPrice  float64 `json:"unit_price"`
	OrderDate  string  `json:"order_date"`
	ExpectedBy string  `json:"expected_by"`
	ProjectID  uint    `json:"project_id"`
}

func CreatePurchaseOrder(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	var req CreatePurchaseOrderRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.VendorName = core.Sanitize(req.VendorName)
	req.ItemName = core.Sanitize(req.ItemName)
	req.Unit = core.Sanitize(req.Unit)
	req.OrderDate = core.Sanitize(req.OrderDate)
	req.ExpectedBy = core.Sanitize(req.ExpectedBy)

	if req.VendorName == "" || req.ItemName == "" || req.Quantity <= 0 || req.UnitPrice <= 0 || req.OrderDate == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Vendor, item, quantity, unit price, and order date are required", nil)
	}
	if !core.IsValidDate(req.OrderDate) {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid order date format. Expected YYYY-MM-DD", nil)
	}

	if req.ProjectID != 0 {
		var project models.Project
		if err := db.DB.First(&project, req.ProjectID).Error; err != nil {
			return core.SendError(c, fiber.StatusNotFound, "Project not found", nil)
		}
		if project.TenantID != tenantID {
			return core.SendError(c, fiber.StatusForbidden, "Access denied to project", nil)
		}
	}

	po := models.PurchaseOrder{
		TenantID:   tenantID,
		VendorName: req.VendorName,
		ItemName:   req.ItemName,
		Quantity:   req.Quantity,
		Unit:       req.Unit,
		UnitPrice:  req.UnitPrice,
		TotalCost:  req.Quantity * req.UnitPrice,
		OrderDate:  req.OrderDate,
		ExpectedBy: req.ExpectedBy,
		ProjectID:  req.ProjectID,
		Status:     "Issued",
	}

	if err := db.DB.Create(&po).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to create purchase order", err)
	}
	return c.Status(fiber.StatusCreated).JSON(po)
}

func UpdatePurchaseOrderStatus(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	poID := c.Params("id")

	var po models.PurchaseOrder
	if err := db.DB.First(&po, poID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Purchase order not found", err)
	}
	if po.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}

	var body struct {
		Status string `json:"status"`
	}
	if err := c.BodyParser(&body); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request", err)
	}

	validStatuses := map[string]bool{"Pending": true, "Approved": true, "Received": true, "Cancelled": true}
	if !validStatuses[body.Status] {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid status. Use: Pending, Approved, Received, Cancelled", nil)
	}

	po.Status = body.Status
	if err := db.DB.Save(&po).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update status", err)
	}
	return c.JSON(po)
}

func DeletePurchaseOrder(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	id := c.Params("id")

	var po models.PurchaseOrder
	if err := db.DB.Where("id = ? AND tenant_id = ?", id, tenantID).First(&po).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Purchase order not found", err)
	}

	if err := db.DB.Delete(&po).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to delete purchase order", err)
	}
	return c.JSON(fiber.Map{"message": "Purchase order deleted successfully"})
}
