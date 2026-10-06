package admin

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/middleware"
	"civilos/backend/internal/models"
	"civilos/backend/internal/services"
	"encoding/json"
	"time"

	"github.com/gofiber/fiber/v2"
)

func ListTenants(c *fiber.Ctx) error {
	page := c.QueryInt("page", 1)
	limit := c.QueryInt("limit", 20)
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	tenants := make([]models.Tenant, 0)
	var total int64

	db.DB.Model(&models.Tenant{}).Count(&total)

	if err := db.DB.Preload("ActiveSubscription").Preload("ActiveSubscription.Plan").Offset(offset).Limit(limit).Order("created_at desc").Find(&tenants).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch tenants", err)
	}

	return c.JSON(fiber.Map{
		"data":  tenants,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

type ToggleFeatureRequest struct {
	FeatureFlags string `json:"feature_flags"` // JSON string representation
}

func ToggleTenantFeatures(c *fiber.Ctx) error {
	tenantID := c.Params("id")
	var req ToggleFeatureRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	// Validate JSON string
	var temp map[string]interface{}
	if err := json.Unmarshal([]byte(req.FeatureFlags), &temp); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Feature flags must be a valid JSON string", err)
	}

	var tenant models.Tenant
	if err := db.DB.First(&tenant, tenantID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Tenant not found", err)
	}

	tenant.FeatureFlags = req.FeatureFlags
	if err := db.DB.Save(&tenant).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update feature flags", err)
	}

	return c.JSON(tenant)
}

func SetTenantStatus(c *fiber.Ctx) error {
	tenantID := c.Params("id")
	var body struct {
		IsActive bool `json:"is_active"`
	}
	if err := c.BodyParser(&body); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	var tenant models.Tenant
	if err := db.DB.First(&tenant, tenantID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Tenant not found", err)
	}

	tenant.IsActive = body.IsActive
	if err := db.DB.Save(&tenant).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update tenant status", err)
	}
	return c.JSON(tenant)
}

type GlobalAnalytics struct {
	TotalMRR    float64 `json:"total_mrr"`
	ActiveUsers int64   `json:"active_users"`
}

func GetGlobalAnalytics(c *fiber.Ctx) error {
	var totalMRR float64
	// Sum MRR across all active tenant subscriptions joined with plans
	db.DB.Table("tenant_subscriptions").
		Joins("JOIN subscription_plans ON subscription_plans.id = tenant_subscriptions.plan_id").
		Where("tenant_subscriptions.status = ?", "active").
		Select("COALESCE(SUM(subscription_plans.price_per_month), 0)").
		Scan(&totalMRR)

	var activeUsers int64
	db.DB.Model(&models.User{}).Count(&activeUsers)

	return c.JSON(GlobalAnalytics{
		TotalMRR:    totalMRR,
		ActiveUsers: activeUsers,
	})
}

func ImpersonateTenant(c *fiber.Ctx) error {
	tenantID := c.Params("id")

	var user models.User
	if err := db.DB.Preload("Tenant").Where("tenant_id = ? AND role = ?", tenantID, "Contractor").First(&user).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "No Contractor found for this tenant", err)
	}

	token, err := middleware.GenerateToken(user.ID, user.Email, user.Role, user.TenantID)
	if err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to generate token", err)
	}

	return c.JSON(fiber.Map{
		"token": token,
		"user":  user,
	})
}

func CreateAnnouncement(c *fiber.Ctx) error {
	var body struct {
		Title   string `json:"title"`
		Message string `json:"message"`
		Type    string `json:"type"`
	}
	if err := c.BodyParser(&body); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	announcement := models.GlobalAnnouncement{
		Title:   body.Title,
		Message: body.Message,
		Type:    body.Type,
	}

	if err := db.DB.Create(&announcement).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to create announcement", err)
	}

	return c.JSON(announcement)
}

func GetAnnouncements(c *fiber.Ctx) error {
	announcements := make([]models.GlobalAnnouncement, 0)
	if err := db.DB.Where("is_active = ?", true).Order("created_at desc").Find(&announcements).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch announcements", err)
	}
	return c.JSON(announcements)
}

type SystemHealth struct {
	Service      string `json:"service"`
	Status       string `json:"status"`
	Latency      string `json:"latency"`
	StorageUsage string `json:"storage_usage"`
}

func GetSystemHealth(c *fiber.Ctx) error {
	apiStart := time.Now()
	apiLatency := time.Since(apiStart).Round(time.Millisecond).String()
	if apiLatency == "0s" {
		apiLatency = "<1ms"
	}

	// Ping database for real latency
	dbStart := time.Now()
	sqlDB, err := db.DB.DB()
	dbLatency := "Unknown"
	dbStatus := "Unhealthy"
	if err == nil {
		if pingErr := sqlDB.Ping(); pingErr == nil {
			dbStatus = "Healthy"
			dbLatency = time.Since(dbStart).Round(time.Millisecond).String()
			if dbLatency == "0s" {
				dbLatency = "<1ms"
			}
		}
	}

	health := []SystemHealth{
		{Service: "Core API (Go)", Status: "Healthy", Latency: apiLatency, StorageUsage: "N/A"},
		{Service: "Database (PostgreSQL)", Status: dbStatus, Latency: dbLatency, StorageUsage: services.CalculateTotalStorage()},
		{Service: "Storage (S3 / Local)", Status: "Healthy", Latency: "<1ms", StorageUsage: services.CalculateTotalStorage()},
	}

	return c.JSON(health)
}

func GetAuditLogs(c *fiber.Ctx) error {
	page := c.QueryInt("page", 1)
	limit := c.QueryInt("limit", 50)
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 1000 {
		limit = 50
	}
	offset := (page - 1) * limit

	logs := make([]models.SystemAuditLog, 0)
	var total int64

	db.DB.Model(&models.SystemAuditLog{}).Count(&total)

	if err := db.DB.Order("timestamp desc").Offset(offset).Limit(limit).Find(&logs).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch audit logs", err)
	}

	return c.JSON(fiber.Map{
		"data":  logs,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

// Removed local LogAudit, using db.LogAudit instead

func GetGlobalUsers(c *fiber.Ctx) error {
	page := c.QueryInt("page", 1)
	limit := c.QueryInt("limit", 20)
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit
	search := c.Query("search", "")

	users := make([]models.User, 0)
	var total int64

	query := db.DB.Model(&models.User{})
	if search != "" {
		query = query.Where("name ILIKE ? OR email ILIKE ?", "%"+search+"%", "%"+search+"%")
	}

	query.Count(&total)

	if err := query.Offset(offset).Limit(limit).Order("created_at desc").Find(&users).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch users", err)
	}

	return c.JSON(fiber.Map{
		"data":  users,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}
