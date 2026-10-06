package finance

import (
	"errors"
	"time"

	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"
)

// BillingService handles invoice and payment business logic.
type BillingService struct{}

func (s *BillingService) ListInvoices(tenantID uint, offset, limit int) ([]models.Invoice, error) {
	invoices := make([]models.Invoice, 0)
	query := db.DB.Preload("Project").Preload("Payments").
		Joins("JOIN projects ON invoices.project_id = projects.id").
		Where("projects.tenant_id = ?", tenantID)

	if err := query.Offset(offset).Limit(limit).Find(&invoices).Error; err != nil {
		return nil, errors.New("failed to fetch invoices")
	}

	for i := range invoices {
		if invoices[i].Payments == nil {
			invoices[i].Payments = []models.Payment{}
		}
		if invoices[i].Status != "Paid" && invoices[i].Status != "Overdue" && invoices[i].DueDate != "" {
			dueTime, err := time.Parse("2006-01-02", invoices[i].DueDate)
			if err == nil && time.Now().After(dueTime) {
				invoices[i].Status = "Overdue"
				db.DB.Model(&invoices[i]).Update("status", "Overdue")
			}
		}
	}
	return invoices, nil
}

func (s *BillingService) CreateInvoice(projectID uint, tenantID uint, input CreateInvoiceInput) (*models.Invoice, error) {
	if input.TotalAmount <= 0 {
		return nil, errors.New("total amount must be greater than zero")
	}
	if !core.IsValidDate(input.IssueDate) || !core.IsValidDate(input.DueDate) {
		return nil, errors.New("invalid date format")
	}
	issueTime, _ := time.Parse("2006-01-02", input.IssueDate)
	dueTime, _ := time.Parse("2006-01-02", input.DueDate)
	if dueTime.Before(issueTime) {
		return nil, errors.New("due date cannot be before issue date")
	}

	var project models.Project
	if err := db.DB.First(&project, projectID).Error; err != nil {
		return nil, errors.New("project not found")
	}
	if project.TenantID != tenantID {
		return nil, errors.New("access denied")
	}

	invoice := models.Invoice{
		ProjectID:     projectID,
		InvoiceNumber: input.InvoiceNumber,
		ClientName:    input.ClientName,
		IssueDate:     input.IssueDate,
		DueDate:       input.DueDate,
		TotalAmount:   input.TotalAmount,
		Status:        "Unpaid",
	}
	if err := db.DB.Create(&invoice).Error; err != nil {
		return nil, errors.New("failed to create invoice")
	}
	return &invoice, nil
}

func (s *BillingService) RecordPayment(invoiceID uint, tenantID uint, input PaymentInput) (*models.Invoice, error) {
	if input.Amount <= 0 || input.PaymentDate == "" {
		return nil, errors.New("payment amount and date are required")
	}
	if !core.IsValidDate(input.PaymentDate) {
		return nil, errors.New("invalid date format")
	}

	tx := db.DB.Begin()

	var invoice models.Invoice
	if err := tx.Preload("Project").Preload("Payments").First(&invoice, invoiceID).Error; err != nil {
		tx.Rollback()
		return nil, errors.New("invoice not found")
	}
	if invoice.Project.TenantID != tenantID {
		tx.Rollback()
		return nil, errors.New("access denied")
	}

	var totalPaid float64
	for _, p := range invoice.Payments {
		totalPaid += p.Amount
	}
	if totalPaid+input.Amount > invoice.TotalAmount {
		tx.Rollback()
		return nil, errors.New("payment amount exceeds remaining balance")
	}

	payment := models.Payment{
		InvoiceID:     invoice.ID,
		Amount:        input.Amount,
		PaymentDate:   input.PaymentDate,
		PaymentMethod: input.PaymentMethod,
		ReferenceNo:   input.ReferenceNo,
		Notes:         input.Notes,
	}
	if err := tx.Create(&payment).Error; err != nil {
		tx.Rollback()
		return nil, errors.New("failed to record payment")
	}

	totalPaid += input.Amount
	if totalPaid >= invoice.TotalAmount {
		invoice.Status = "Paid"
	} else if totalPaid > 0 {
		invoice.Status = "Partial"
	}
	if err := tx.Save(&invoice).Error; err != nil {
		tx.Rollback()
		return nil, errors.New("failed to update invoice status")
	}

	tx.Commit()

	db.DB.Preload("Project").Preload("Payments").First(&invoice, invoice.ID)
	return &invoice, nil
}

type CreateInvoiceInput struct {
	InvoiceNumber string
	ClientName    string
	IssueDate     string
	DueDate       string
	TotalAmount   float64
}

type PaymentInput struct {
	Amount        float64
	PaymentDate   string
	PaymentMethod string
	ReferenceNo   string
	Notes         string
}
