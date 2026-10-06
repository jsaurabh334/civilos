package db

import (
	"log/slog"
	"time"

	"gorm.io/gorm"
)

// Migration represents a single database migration for version-controlled schema changes.
type Migration struct {
	Version     string
	Description string
	Up          func(tx *gorm.DB) error
}

var pendingMigrations = []Migration{}

func RegisterMigration(m Migration) {
	pendingMigrations = append(pendingMigrations, m)
}

// RunMigrations applies all pending migrations that haven't been applied yet.
func RunMigrations() {
	if err := DB.AutoMigrate(&SchemaMigration{}); err != nil {
		slog.Error("failed to create schema_migrations table", slog.String("error", err.Error()))
		return
	}

	for _, m := range pendingMigrations {
		var count int64
		DB.Model(&SchemaMigration{}).Where("version = ?", m.Version).Count(&count)
		if count > 0 {
			continue
		}

		slog.Info("applying migration", slog.String("version", m.Version), slog.String("desc", m.Description))

		tx := DB.Begin()
		if err := m.Up(tx); err != nil {
			tx.Rollback()
			slog.Error("migration failed", slog.String("version", m.Version), slog.String("error", err.Error()))
			return
		}
		if err := tx.Create(&SchemaMigration{Version: m.Version, AppliedAt: time.Now()}).Error; err != nil {
			tx.Rollback()
			slog.Error("failed to record migration", slog.String("version", m.Version), slog.String("error", err.Error()))
			return
		}
		tx.Commit()
		slog.Info("migration applied", slog.String("version", m.Version))
	}
}

// SchemaMigration tracks which migrations have been applied.
type SchemaMigration struct {
	ID        uint      `gorm:"primaryKey"`
	Version   string    `gorm:"uniqueIndex;not null;size:255"`
	AppliedAt time.Time `gorm:"not null"`
}

// Usage: Call RegisterMigration in init() functions in this package.
// For future migrations, add a new file or function:
//
//	func init() {
//	    RegisterMigration(Migration{
//	        Version:     "2026_07_01_001",
//	        Description: "Add soft_delete to projects",
//	        Up: func(tx *gorm.DB) error {
//	            return tx.Exec("ALTER TABLE projects ADD COLUMN deleted_at datetime").Error
//	        },
//	    })
//	}
