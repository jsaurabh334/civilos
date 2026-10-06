package db

import (
	"gorm.io/gorm"
)

func init() {
	RegisterMigration(Migration{
		Version:     "2026_07_01_001_add_tenant_indexes",
		Description: "Add compound indexes on tenant_id for faster querying",
		Up: func(tx *gorm.DB) error {
			// Add an index on projects for faster tenant-scoped queries
			// Note: projects table uses 'status' not 'is_active'
			if !tx.Migrator().HasIndex("projects", "idx_projects_tenant_status") {
				tx.Exec("CREATE INDEX IF NOT EXISTS idx_projects_tenant_status ON projects(tenant_id, status)")
			}

			// Add an index on inventory items
			if !tx.Migrator().HasIndex("inventory_items", "idx_inventory_tenant") {
				tx.Exec("CREATE INDEX IF NOT EXISTS idx_inventory_tenant ON inventory_items(tenant_id)")
			}

			return nil
		},
	})
}
