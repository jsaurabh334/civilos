package testutil

import (
	"log"
	"os"
	"strings"
	"testing"
	"time"

	"civilos/backend/internal/db"
	"civilos/backend/internal/middleware"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func SetupTestDB(t *testing.T) *gorm.DB {
	t.Helper()

	os.Setenv("JWT_SECRET", "test-secret-for-unit-tests")

	testDB, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{
		SkipDefaultTransaction: true,
	})
	if err != nil {
		t.Fatalf("failed to open test DB: %v", err)
	}

	err = testDB.AutoMigrate(
		&models.Tenant{},
		&models.User{},
		&models.Project{},
		&models.BOQItem{},
		&models.DailyDiaryEntry{},
		&models.WorkOrder{},
		&models.Inspection{},
		&models.Checklist{},
		&models.Expense{},
		&models.Machinery{},
		&models.MachineryLog{},
		&models.LaborWorker{},
		&models.AttendanceLog{},
		&models.PayrollRecord{},
		&models.InventoryItem{},
		&models.MaterialTransaction{},
		&models.Invoice{},
		&models.Payment{},
		&models.PurchaseOrder{},
		&models.Message{},
		&models.Notification{},
	)
	if err != nil {
		if strings.Contains(err.Error(), "already exists") {
			log.Printf("ignoring migration warning: %v", err)
		} else {
			t.Fatalf("failed to migrate test DB: %v", err)
		}
	}

	db.DB = testDB
	return testDB
}

func CreateTestTenant(t *testing.T) models.Tenant {
	t.Helper()
	slug := "test-" + strings.ReplaceAll(time.Now().Format("150405.000000"), ".", "")
	tenant := models.Tenant{
		Name:     "Test Tenant " + slug,
		Slug:     slug,
		IsActive: true,
	}
	if err := db.DB.Create(&tenant).Error; err != nil {
		t.Fatalf("failed to create test tenant: %v", err)
	}
	return tenant
}

func CreateTestUser(t *testing.T, tenantID uint, role string) models.User {
	t.Helper()
	hash, err := bcrypt.GenerateFromPassword([]byte("Password123"), bcrypt.DefaultCost)
	if err != nil {
		t.Fatalf("failed to hash password: %v", err)
	}
	user := models.User{
		Name:         "Test " + role,
		Email:        role + "+" + time.Now().Format("150405.000000") + "@test.com",
		PasswordHash: string(hash),
		Role:         role,
		TenantID:     &tenantID,
	}
	if err := db.DB.Create(&user).Error; err != nil {
		t.Fatalf("failed to create test user: %v", err)
	}
	return user
}

func CreateTestProject(t *testing.T, tenantID uint, name string) models.Project {
	t.Helper()
	project := models.Project{
		Name:     name + " " + time.Now().Format("150405.000000"),
		TenantID: tenantID,
	}
	if err := db.DB.Create(&project).Error; err != nil {
		t.Fatalf("failed to create test project: %v", err)
	}
	return project
}

func GenerateTestToken(userID uint, email, role string, tenantID *uint) string {
	token, err := middleware.GenerateToken(userID, email, role, tenantID)
	if err != nil {
		panic("failed to generate test token: " + err.Error())
	}
	return token
}

func SetupTestApp() *fiber.App {
	app := fiber.New()
	return app
}
