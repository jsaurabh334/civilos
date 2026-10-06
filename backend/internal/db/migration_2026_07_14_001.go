package db

import (
	"gorm.io/gorm"
)

func init() {
	RegisterMigration(Migration{
		Version:     "2026_07_14_001",
		Description: "Backfill tenant_id on machinery_logs and add NOT NULL constraint safely",
		Up: func(tx *gorm.DB) error {
			// Step 1: Set NULL tenant_id rows to the minimum valid tenant_id
			// This safely backfills any legacy rows created before the tenant_id column existed
			if err := tx.Exec(`
				UPDATE machinery_logs
				SET tenant_id = (
					SELECT COALESCE(MIN(id), 1) FROM tenants
				)
				WHERE tenant_id IS NULL OR tenant_id = 0
			`).Error; err != nil {
				return err
			}
			return nil
		},
	})
}
