package projects

import (
	"time"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"
)

// DashboardService provides aggregated business metrics.
type DashboardService struct{}

func (s *DashboardService) GetStats(tenantID uint) map[string]interface{} {
	var projStats struct {
		Total    int64
		Active   int64
		Contract float64
	}
	db.DB.Model(&models.Project{}).Where("tenant_id = ?", tenantID).
		Select(`
			COUNT(id) as total,
			COUNT(CASE WHEN status IN ('Active', 'In Progress') THEN 1 END) as active,
			COALESCE(SUM(budget), 0) as contract
		`).Scan(&projStats)

	var workerCount int64
	db.DB.Model(&models.LaborWorker{}).Where("tenant_id = ?", tenantID).Count(&workerCount)

	today := time.Now().Format("2006-01-02")
	var presentToday int64
	db.DB.Model(&models.AttendanceLog{}).
		Joins("JOIN labor_workers ON attendance_logs.labor_worker_id = labor_workers.id").
		Where("labor_workers.tenant_id = ? AND attendance_logs.date = ? AND attendance_logs.status IN ?", tenantID, today, []string{"Present", "Overtime"}).
		Count(&presentToday)

	invoices := make([]models.Invoice, 0)
	db.DB.Preload("Payments").
		Joins("JOIN projects ON invoices.project_id = projects.id").
		Where("projects.tenant_id = ? AND invoices.status IN ?", tenantID, []string{"Unpaid", "Partial"}).
		Find(&invoices)

	var totalOutstanding float64
	for _, inv := range invoices {
		var paid float64
		for _, p := range inv.Payments {
			paid += p.Amount
		}
		totalOutstanding += inv.TotalAmount - paid
	}

	var lowStockCount int64
	db.DB.Model(&models.InventoryItem{}).
		Where("tenant_id = ? AND quantity <= safety_stock AND safety_stock > 0", tenantID).
		Count(&lowStockCount)

	var macCount int64
	db.DB.Model(&models.Machinery{}).Where("tenant_id = ? AND status = ?", tenantID, "Active").Count(&macCount)

	var expStats struct {
		Total   float64
		Monthly float64
	}
	currentMonth := time.Now().Format("2006-01")
	db.DB.Model(&models.Expense{}).Where("tenant_id = ?", tenantID).
		Select(`
			COALESCE(SUM(amount), 0) as total,
			COALESCE(SUM(CASE WHEN expense_date LIKE ? THEN amount ELSE 0 END), 0) as monthly
		`, currentMonth+"%").Scan(&expStats)

	var unpaidPayroll int64
	db.DB.Model(&models.PayrollRecord{}).
		Joins("JOIN labor_workers ON payroll_records.labor_worker_id = labor_workers.id").
		Where("labor_workers.tenant_id = ? AND payroll_records.status = ?", tenantID, "Unpaid").
		Count(&unpaidPayroll)

	return map[string]interface{}{
		"total_projects":          projStats.Total,
		"active_projects":         projStats.Active,
		"total_contract_value":    projStats.Contract,
		"cost_incurred":           expStats.Total,
		"total_workers":           workerCount,
		"workers_present_today":   presentToday,
		"outstanding_receivables": totalOutstanding,
		"low_stock_items":         lowStockCount,
		"active_machinery":        macCount,
		"monthly_expenses":        expStats.Monthly,
		"unpaid_payroll_count":    unpaidPayroll,
	}
}
