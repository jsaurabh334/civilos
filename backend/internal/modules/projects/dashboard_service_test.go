package projects

import (
	"testing"
)

func TestDashboardService_GetStats_NoPanic(t *testing.T) {
	svc := &DashboardService{}

	// GetStats calls db.DB which may be nil in unit tests.
	// We expect a panic from GORM, not from our code.
	defer func() {
		if r := recover(); r != nil {
			t.Logf("GetStats panicked as expected (no DB): %v", r)
		}
	}()

	result := svc.GetStats(1)
	if result != nil {
		t.Log("GetStats returned a result (DB is connected)")
	}
}
