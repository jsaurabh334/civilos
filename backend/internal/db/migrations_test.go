package db

import (
	"testing"
	"time"

	"gorm.io/gorm"
)

func TestMigrationStruct(t *testing.T) {
	m := Migration{
		Version:     "2026_07_01_001",
		Description: "Test migration",
		Up: func(tx *gorm.DB) error {
			return nil
		},
	}
	if m.Version != "2026_07_01_001" {
		t.Errorf("Migration.Version = %q; want %q", m.Version, "2026_07_01_001")
	}
	if m.Description != "Test migration" {
		t.Errorf("Migration.Description = %q; want %q", m.Description, "Test migration")
	}
	if m.Up == nil {
		t.Error("Migration.Up should not be nil")
	}

	// Verify the migration function works
	if err := m.Up(nil); err != nil {
		t.Errorf("Migration.Up returned error: %v", err)
	}
}

func TestSchemaMigrationStruct(t *testing.T) {
	now := time.Now()
	sm := SchemaMigration{
		Version:   "2026_07_01_001",
		AppliedAt: now,
	}
	if sm.Version != "2026_07_01_001" {
		t.Errorf("SchemaMigration.Version = %q; want %q", sm.Version, "2026_07_01_001")
	}
	if !sm.AppliedAt.Equal(now) {
		t.Errorf("SchemaMigration.AppliedAt mismatch")
	}
}

func TestPendingMigrations(t *testing.T) {
	initialCount := len(pendingMigrations)

	m := Migration{
		Version:     "2026_test_001",
		Description: "Test registration",
		Up: func(tx *gorm.DB) error {
			return nil
		},
	}
	RegisterMigration(m)

	if len(pendingMigrations) != initialCount+1 {
		t.Errorf("pendingMigrations count = %d; want %d", len(pendingMigrations), initialCount+1)
	}

	last := pendingMigrations[len(pendingMigrations)-1]
	if last.Version != "2026_test_001" {
		t.Errorf("Last migration version = %q; want %q", last.Version, "2026_test_001")
	}
}
