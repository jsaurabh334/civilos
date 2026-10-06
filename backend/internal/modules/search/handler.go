package search

import (
	"strings"

	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

// GlobalSearch performs a cross-module full-text search
func GlobalSearch(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	q := strings.TrimSpace(c.Query("q"))
	if len(q) < 2 {
		return core.SendError(c, fiber.StatusBadRequest, "Query must be at least 2 characters", nil)
	}

	like := "%" + q + "%"

	// Projects
	projects := []models.Project{}
	db.DB.Where("tenant_id = ? AND (name LIKE ? OR location LIKE ? OR description LIKE ?)", tenantID, like, like, like).
		Limit(10).Find(&projects)

	// Inventory
	inventory := []models.InventoryItem{}
	db.DB.Where("tenant_id = ? AND (item_name LIKE ? OR sku LIKE ? OR category LIKE ?)", tenantID, like, like, like).
		Limit(10).Find(&inventory)

	// Workers (LaborWorkers)
	workers := []models.LaborWorker{}
	db.DB.Where("tenant_id = ? AND (name LIKE ? OR skill_category LIKE ?)", tenantID, like, like).
		Limit(10).Find(&workers)

	// Vendors (B2B directory)
	type VendorResult struct {
		ID          uint   `json:"id"`
		CompanyName string `json:"company_name"`
		Category    string `json:"category"`
		City        string `json:"city"`
	}
	vendors := []VendorResult{}
	db.DB.Model(&models.B2BPartner{}).
		Select("id, name as company_name, type as category, location as city").
		Where("name LIKE ? OR type LIKE ? OR location LIKE ? OR services LIKE ?", like, like, like, like).
		Limit(10).Find(&vendors)

	// Tasks (work orders)
	tasks := []models.Task{}
	db.DB.Where("tenant_id = ? AND (title LIKE ? OR description LIKE ?)", tenantID, like, like).
		Limit(10).Find(&tasks)

	// Invoices
	type InvoiceResult struct {
		ID            uint   `json:"id"`
		InvoiceNumber string `json:"invoice_number"`
		Status        string `json:"status"`
	}
	invoices := []InvoiceResult{}
	db.DB.Model(&models.Invoice{}).
		Select("id, invoice_number, status").
		Where("(invoice_number LIKE ? OR status LIKE ?) AND project_id IN (SELECT id FROM projects WHERE tenant_id = ?)", like, like, tenantID).
		Limit(10).Find(&invoices)

	totalResults := len(projects) + len(inventory) + len(workers) + len(vendors) + len(tasks) + len(invoices)

	return c.JSON(fiber.Map{
		"query":     q,
		"total":     totalResults,
		"projects":  projects,
		"inventory": inventory,
		"workers":   workers,
		"vendors":   vendors,
		"tasks":     tasks,
		"invoices":  invoices,
	})
}
