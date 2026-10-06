package finance

import (
	"strconv"

	"civilos/backend/internal/core"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func ListInvoices(c *fiber.Ctx) error {
	role := c.Locals("role").(string)
	offset, limit := core.GetPagination(c)

	if role == "SuperAdmin" {
		var invoices []models.Invoice
		if err := db.DB.Preload("Project").Preload("Payments").Offset(offset).Limit(limit).Find(&invoices).Error; err != nil {
			return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch invoices", err)
		}
		return c.JSON(invoices)
	}

	tenantID := c.Locals("tenant_id_value").(uint)
	svc := BillingService{}
	invoices, err := svc.ListInvoices(tenantID, offset, limit)
	if err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, err.Error(), err)
	}
	return c.JSON(invoices)
}

type CreateInvoiceRequest struct {
	ProjectID     uint    `json:"project_id"`
	InvoiceNumber string  `json:"invoice_number"`
	ClientName    string  `json:"client_name"`
	IssueDate     string  `json:"issue_date"`
	DueDate       string  `json:"due_date"`
	TotalAmount   float64 `json:"total_amount"`
}

func CreateInvoice(c *fiber.Ctx) error {
	var req CreateInvoiceRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.InvoiceNumber = core.Sanitize(req.InvoiceNumber)
	req.ClientName = core.Sanitize(req.ClientName)
	req.IssueDate = core.Sanitize(req.IssueDate)
	req.DueDate = core.Sanitize(req.DueDate)

	if req.ProjectID == 0 || req.InvoiceNumber == "" || req.ClientName == "" || req.IssueDate == "" || req.DueDate == "" {
		return core.SendError(c, fiber.StatusBadRequest, "ProjectID, InvoiceNumber, ClientName, IssueDate, and DueDate are required", nil)
	}

	tenantID := c.Locals("tenant_id_value").(uint)
	svc := BillingService{}
	input := CreateInvoiceInput{
		InvoiceNumber: req.InvoiceNumber,
		ClientName:    req.ClientName,
		IssueDate:     req.IssueDate,
		DueDate:       req.DueDate,
		TotalAmount:   req.TotalAmount,
	}
	invoice, err := svc.CreateInvoice(req.ProjectID, tenantID, input)
	if err != nil {
		switch err.Error() {
		case "project not found":
			return core.SendError(c, fiber.StatusNotFound, err.Error(), err)
		case "access denied":
			return core.SendError(c, fiber.StatusForbidden, err.Error(), err)
		default:
			return core.SendError(c, fiber.StatusBadRequest, err.Error(), err)
		}
	}
	return c.Status(fiber.StatusCreated).JSON(invoice)
}

type RecordPaymentRequest struct {
	Amount        float64 `json:"amount"`
	PaymentDate   string  `json:"payment_date"`
	PaymentMethod string  `json:"payment_method"`
	ReferenceNo   string  `json:"reference_no"`
	Notes         string  `json:"notes"`
}

func RecordPayment(c *fiber.Ctx) error {
	invoiceIDStr := c.Params("id")
	var req RecordPaymentRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	invoiceID, err := strconv.ParseUint(invoiceIDStr, 10, 64)
	if err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid invoice ID", nil)
	}

	tenantID := c.Locals("tenant_id_value").(uint)
	svc := BillingService{}
	input := PaymentInput{
		Amount:        req.Amount,
		PaymentDate:   core.Sanitize(req.PaymentDate),
		PaymentMethod: core.Sanitize(req.PaymentMethod),
		ReferenceNo:   core.Sanitize(req.ReferenceNo),
		Notes:         core.Sanitize(req.Notes),
	}
	invoice, err := svc.RecordPayment(uint(invoiceID), tenantID, input)
	if err != nil {
		switch err.Error() {
		case "invoice not found":
			return core.SendError(c, fiber.StatusNotFound, err.Error(), err)
		case "access denied":
			return core.SendError(c, fiber.StatusForbidden, err.Error(), err)
		default:
			return core.SendError(c, fiber.StatusBadRequest, err.Error(), err)
		}
	}
	return c.Status(fiber.StatusCreated).JSON(invoice)
}

type UpdateInvoiceRequest struct {
	ClientName  string  `json:"client_name"`
	DueDate     string  `json:"due_date"`
	TotalAmount float64 `json:"total_amount"`
	TaxAmount   float64 `json:"tax_amount"`
	Status      string  `json:"status"` // Cancelled only
}

func UpdateInvoice(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	invoiceID := c.Params("id")

	var invoice models.Invoice
	if err := db.DB.Preload("Project").First(&invoice, invoiceID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Invoice not found", err)
	}
	if invoice.Project.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}
	if invoice.Status == "Paid" {
		return core.SendError(c, fiber.StatusBadRequest, "Cannot edit a fully paid invoice", nil)
	}

	var req UpdateInvoiceRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.ClientName = core.Sanitize(req.ClientName)
	req.DueDate = core.Sanitize(req.DueDate)

	if req.ClientName != "" {
		invoice.ClientName = req.ClientName
	}
	if req.DueDate != "" {
		if !core.IsValidDate(req.DueDate) {
			return core.SendError(c, fiber.StatusBadRequest, "Invalid due date format", nil)
		}
		invoice.DueDate = req.DueDate
	}
	if req.TotalAmount > 0 {
		invoice.TotalAmount = req.TotalAmount
	}
	if req.TaxAmount >= 0 {
		invoice.TaxAmount = req.TaxAmount
	}
	if req.Status == "Cancelled" {
		invoice.Status = "Cancelled"
	}

	if err := db.DB.Save(&invoice).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update invoice", err)
	}
	db.DB.Preload("Project").Preload("Payments").First(&invoice, invoice.ID)
	if invoice.Payments == nil {
		invoice.Payments = []models.Payment{}
	}
	return c.JSON(invoice)
}

// ContractorApproveInvoice approves an invoice for payment
func ContractorApproveInvoice(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	invoiceID := c.Params("id")

	var invoice models.Invoice
	if err := db.DB.Where("id = ? AND tenant_id = ?", invoiceID, tenantID).First(&invoice).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Invoice not found", err)
	}

	invoice.Status = "Approved"
	if err := db.DB.Save(&invoice).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to approve invoice", err)
	}

	return c.JSON(fiber.Map{"message": "Invoice approved successfully", "invoice": invoice})
}

// ContractorRejectInvoice rejects an invoice
func ContractorRejectInvoice(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	invoiceID := c.Params("id")

	var invoice models.Invoice
	if err := db.DB.Where("id = ? AND tenant_id = ?", invoiceID, tenantID).First(&invoice).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Invoice not found", err)
	}

	invoice.Status = "Rejected"
	if err := db.DB.Save(&invoice).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to reject invoice", err)
	}

	return c.JSON(fiber.Map{"message": "Invoice rejected successfully", "invoice": invoice})
}

// ContractorDisputeInvoice raises a dispute on an invoice
func ContractorDisputeInvoice(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	invoiceID := c.Params("id")

	var invoice models.Invoice
	if err := db.DB.Where("id = ? AND tenant_id = ?", invoiceID, tenantID).First(&invoice).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Invoice not found", err)
	}

	invoice.Status = "Disputed"
	if err := db.DB.Save(&invoice).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to dispute invoice", err)
	}

	return c.JSON(fiber.Map{"message": "Invoice disputed successfully", "invoice": invoice})
}
