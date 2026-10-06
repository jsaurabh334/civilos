package finance

import (
	"testing"
)

func TestCreateInvoiceInput(t *testing.T) {
	input := CreateInvoiceInput{
		InvoiceNumber: "INV-001",
		ClientName:    "Test Client",
		IssueDate:     "2026-01-01",
		DueDate:       "2026-02-01",
		TotalAmount:   1000,
	}
	if input.InvoiceNumber != "INV-001" {
		t.Errorf("InvoiceNumber = %q; want %q", input.InvoiceNumber, "INV-001")
	}
	if input.TotalAmount != 1000 {
		t.Errorf("TotalAmount = %f; want %f", input.TotalAmount, 1000.0)
	}
}

func TestPaymentInput(t *testing.T) {
	input := PaymentInput{
		Amount:        500,
		PaymentDate:   "2026-01-15",
		PaymentMethod: "BankTransfer",
		ReferenceNo:   "TXN123",
		Notes:         "Test payment",
	}
	if input.Amount != 500 {
		t.Errorf("Amount = %f; want %f", input.Amount, 500.0)
	}
	if input.PaymentMethod != "BankTransfer" {
		t.Errorf("PaymentMethod = %q; want %q", input.PaymentMethod, "BankTransfer")
	}
}
