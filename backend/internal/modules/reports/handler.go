package reports

import (
	"time"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func GetCostReport(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	year := c.Query("year", time.Now().Format("2006"))
	month := c.Query("month", "")

	query := db.DB.Model(&models.Expense{}).Where("tenant_id = ?", tenantID)
	if month != "" {
		query = query.Where("expense_date LIKE ?", year+"-"+month+"%")
	} else {
		query = query.Where("expense_date LIKE ?", year+"%")
	}

	var totalExpenses float64
	query.Select("COALESCE(SUM(amount), 0)").Scan(&totalExpenses)

	type CategoryBreakdown struct {
		Category string  `json:"category"`
		Amount   float64 `json:"amount"`
		Count    int64   `json:"count"`
	}
	byCategory := []CategoryBreakdown{}
	query.Select("category, COALESCE(SUM(amount), 0) as amount, COUNT(*) as count").
		Group("category").Order("amount desc").Find(&byCategory)

	type MonthlyBreakdown struct {
		Month  string  `json:"month"`
		Amount float64 `json:"amount"`
	}
	byMonth := []MonthlyBreakdown{}
	baseQuery := db.DB.Model(&models.Expense{}).Where("tenant_id = ? AND expense_date LIKE ?", tenantID, year+"%")
	baseQuery.Select("SUBSTR(expense_date, 6, 2) as month, COALESCE(SUM(amount), 0) as amount").
		Group("month").Order("month").Find(&byMonth)

	return c.JSON(fiber.Map{
		"year":        year,
		"total":       totalExpenses,
		"by_category": byCategory,
		"by_month":    byMonth,
	})
}

func GetLaborReport(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	var totalWorkers int64
	db.DB.Model(&models.LaborWorker{}).Where("tenant_id = ?", tenantID).Count(&totalWorkers)

	type SkillBreakdown struct {
		Skill  string  `json:"skill"`
		Count  int64   `json:"count"`
		AvgPay float64 `json:"avg_daily_rate"`
	}
	bySkill := []SkillBreakdown{}
	db.DB.Model(&models.LaborWorker{}).
		Select("skill_category as skill, COUNT(*) as count, COALESCE(AVG(daily_rate), 0) as avg_daily_rate").
		Where("tenant_id = ?", tenantID).
		Group("skill_category").Order("count desc").Find(&bySkill)

	var monthlyPayroll float64
	currentMonth := time.Now().Format("2006-01")
	db.DB.Model(&models.PayrollRecord{}).
		Joins("JOIN labor_workers ON payroll_records.labor_worker_id = labor_workers.id").
		Where("labor_workers.tenant_id = ? AND payroll_records.month = ?", tenantID, currentMonth).
		Select("COALESCE(SUM(wages_earned), 0)").Scan(&monthlyPayroll)

	today := time.Now().Format("2006-01-02")
	var presentToday int64
	db.DB.Model(&models.AttendanceLog{}).
		Joins("JOIN labor_workers ON attendance_logs.labor_worker_id = labor_workers.id").
		Where("labor_workers.tenant_id = ? AND attendance_logs.date = ? AND attendance_logs.status IN ?", tenantID, today, []string{"Present", "Overtime"}).
		Count(&presentToday)

	attendanceRate := 0.0
	if totalWorkers > 0 {
		attendanceRate = float64(presentToday) / float64(totalWorkers) * 100
	}

	return c.JSON(fiber.Map{
		"total_workers":   totalWorkers,
		"by_skill":        bySkill,
		"monthly_payroll": monthlyPayroll,
		"present_today":   presentToday,
		"attendance_rate": attendanceRate,
	})
}

func GetMachineryReport(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	var totalMachinery int64
	db.DB.Model(&models.Machinery{}).Where("tenant_id = ?", tenantID).Count(&totalMachinery)

	type StatusBreakdown struct {
		Status string `json:"status"`
		Count  int64  `json:"count"`
	}
	byStatus := []StatusBreakdown{}
	db.DB.Model(&models.Machinery{}).
		Select("status, COUNT(*) as count").
		Where("tenant_id = ?", tenantID).
		Group("status").Order("count desc").Find(&byStatus)

	var totalHours float64
	db.DB.Model(&models.Machinery{}).
		Where("tenant_id = ?", tenantID).
		Select("COALESCE(SUM(total_hours_run), 0)").Scan(&totalHours)

	var avgHourlyRate float64
	db.DB.Model(&models.Machinery{}).
		Where("tenant_id = ?", tenantID).
		Select("COALESCE(AVG(hourly_rate), 0)").Scan(&avgHourlyRate)

	return c.JSON(fiber.Map{
		"total_machinery": totalMachinery,
		"by_status":       byStatus,
		"total_hours":     totalHours,
		"avg_hourly_rate": avgHourlyRate,
	})
}
