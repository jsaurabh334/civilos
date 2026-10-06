package finance

import (
	"bytes"
	"civilos/backend/internal/core"
	"encoding/csv"
	"fmt"
	"strconv"
	"time"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
	"github.com/jung-kurt/gofpdf"
)

func ExportExpensesCSV(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	expenses := make([]models.Expense, 0)
	db.DB.Where("tenant_id = ?", tenantID).Order("expense_date DESC").Find(&expenses)

	c.Set("Content-Type", "text/csv")
	c.Set("Content-Disposition", "attachment; filename=expenses_"+time.Now().Format("2006-01-02")+".csv")

	writer := csv.NewWriter(c)
	defer writer.Flush()

	writer.Write([]string{"ID", "Category", "Amount", "Description", "Expense Date", "Project ID", "Created At"})
	for _, e := range expenses {
		writer.Write([]string{
			strconv.Itoa(int(e.ID)),
			e.Category,
			fmt.Sprintf("%.2f", e.Amount),
			e.Description,
			e.ExpenseDate,
			strconv.Itoa(int(e.ProjectID)),
			e.CreatedAt.Format("2006-01-02 15:04:05"),
		})
	}
	return nil
}

func ExportLaborCSV(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	workers := make([]models.LaborWorker, 0)
	db.DB.Where("tenant_id = ?", tenantID).Order("name").Find(&workers)

	c.Set("Content-Type", "text/csv")
	c.Set("Content-Disposition", "attachment; filename=labor_"+time.Now().Format("2006-01-02")+".csv")

	writer := csv.NewWriter(c)
	defer writer.Flush()

	writer.Write([]string{"ID", "Name", "Skill Category", "Daily Rate", "Created At"})
	for _, w := range workers {
		writer.Write([]string{
			strconv.Itoa(int(w.ID)),
			w.Name,
			w.SkillCategory,
			fmt.Sprintf("%.2f", w.DailyRate),
			w.CreatedAt.Format("2006-01-02 15:04:05"),
		})
	}
	return nil
}

func ExportInventoryCSV(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	items := make([]models.InventoryItem, 0)
	db.DB.Where("tenant_id = ?", tenantID).Order("item_name").Find(&items)

	c.Set("Content-Type", "text/csv")
	c.Set("Content-Disposition", "attachment; filename=inventory_"+time.Now().Format("2006-01-02")+".csv")

	writer := csv.NewWriter(c)
	defer writer.Flush()

	writer.Write([]string{"ID", "Item Name", "SKU", "Category", "Unit", "Quantity", "Safety Stock"})
	for _, item := range items {
		writer.Write([]string{
			strconv.Itoa(int(item.ID)),
			item.ItemName,
			item.SKU,
			item.Category,
			item.Unit,
			fmt.Sprintf("%.2f", item.Quantity),
			fmt.Sprintf("%.2f", item.SafetyStock),
		})
	}
	return nil
}

func ExportInvoicePDF(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	idParam := c.Params("id")
	id, err := strconv.ParseUint(idParam, 10, 64)
	if err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid invoice ID", err)
	}

	var invoice models.Invoice
	if err := db.DB.Preload("Project").Preload("Payments").First(&invoice, id).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Invoice not found", err)
	}

	var tenant models.Tenant
	db.DB.First(&tenant, tenantID)

	pdf := gofpdf.New("P", "mm", "A4", "")
	pdf.SetMargins(20, 20, 20)
	pdf.AddPage()

	pdf.SetFont("Helvetica", "B", 24)
	pdf.Cell(0, 15, "INVOICE")
	pdf.Ln(20)

	pdf.SetFont("Helvetica", "", 10)
	pdf.Cell(0, 6, fmt.Sprintf("Invoice #: %s", invoice.InvoiceNumber))
	pdf.Ln(6)
	pdf.Cell(0, 6, fmt.Sprintf("Date: %s", invoice.IssueDate))
	pdf.Ln(6)
	pdf.Cell(0, 6, fmt.Sprintf("Due Date: %s", invoice.DueDate))
	pdf.Ln(6)
	pdf.Cell(0, 6, fmt.Sprintf("Status: %s", invoice.Status))
	pdf.Ln(12)

	pdf.SetFont("Helvetica", "B", 12)
	pdf.Cell(0, 8, "Bill To:")
	pdf.Ln(8)
	pdf.SetFont("Helvetica", "", 10)
	pdf.Cell(0, 6, invoice.ClientName)
	pdf.Ln(6)
	if invoice.Project.ID != 0 {
		pdf.Cell(0, 6, fmt.Sprintf("Project: %s", invoice.Project.Name))
		pdf.Ln(6)
	}
	pdf.Ln(10)

	pdf.SetFont("Helvetica", "B", 10)
	pdf.SetFillColor(240, 240, 240)
	pdf.CellFormat(130, 8, "Description", "1", 0, "L", true, 0, "")
	pdf.CellFormat(40, 8, "Amount", "1", 0, "R", true, 0, "")
	pdf.Ln(8)

	pdf.SetFont("Helvetica", "", 10)
	pdf.SetFillColor(255, 255, 255)
	pdf.CellFormat(130, 8, fmt.Sprintf("Invoice Item (%s)", invoice.InvoiceNumber), "1", 0, "L", true, 0, "")
	pdf.CellFormat(40, 8, fmt.Sprintf("₹%.2f", invoice.TotalAmount), "1", 0, "R", true, 0, "")
	pdf.Ln(8)

	if invoice.DiscountAmount > 0 {
		pdf.CellFormat(130, 8, "Discount", "1", 0, "L", true, 0, "")
		pdf.CellFormat(40, 8, fmt.Sprintf("-₹%.2f", invoice.DiscountAmount), "1", 0, "R", true, 0, "")
		pdf.Ln(8)
	}

	if invoice.TaxAmount > 0 {
		pdf.CellFormat(130, 8, "Tax", "1", 0, "L", true, 0, "")
		pdf.CellFormat(40, 8, fmt.Sprintf("₹%.2f", invoice.TaxAmount), "1", 0, "R", true, 0, "")
		pdf.Ln(8)
	}

	pdf.SetFont("Helvetica", "B", 10)
	netTotal := invoice.NetTotal
	if netTotal == 0 {
		netTotal = invoice.TotalAmount - invoice.DiscountAmount + invoice.TaxAmount
	}
	pdf.CellFormat(130, 8, "Net Total", "1", 0, "L", true, 0, "")
	pdf.CellFormat(40, 8, fmt.Sprintf("₹%.2f", netTotal), "1", 0, "R", true, 0, "")
	pdf.Ln(15)

	if len(invoice.Payments) > 0 {
		pdf.SetFont("Helvetica", "B", 12)
		pdf.Cell(0, 8, "Payments")
		pdf.Ln(8)
		pdf.SetFont("Helvetica", "", 10)
		for _, p := range invoice.Payments {
			pdf.Cell(0, 6, fmt.Sprintf("₹%.2f on %s (%s)", p.Amount, p.PaymentDate, p.PaymentMethod))
			pdf.Ln(6)
		}
	}

	pdf.Ln(20)
	pdf.SetFont("Helvetica", "I", 8)
	pdf.Cell(0, 5, fmt.Sprintf("Generated by CivilOS on %s", time.Now().Format("2006-01-02 15:04:05")))
	pdf.Ln(5)
	pdf.Cell(0, 5, fmt.Sprintf("Tenant: %s", tenant.Name))

	c.Set("Content-Type", "application/pdf")
	c.Set("Content-Disposition", fmt.Sprintf("attachment; filename=invoice_%s.pdf", invoice.InvoiceNumber))
	var buf bytes.Buffer
	if err := pdf.Output(&buf); err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to generate PDF", err)
	}
	return c.Send(buf.Bytes())
}
