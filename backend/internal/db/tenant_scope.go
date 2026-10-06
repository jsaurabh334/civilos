package db

import (
	"gorm.io/gorm"
)

// ForTenant creates a strict global scope ensuring queries are locked to a specific tenant.
func ForTenant(tenantID uint) *gorm.DB {
	return DB.Where("tenant_id = ?", tenantID)
}
