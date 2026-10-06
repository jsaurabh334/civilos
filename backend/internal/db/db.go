package db

import (
	"fmt"
	"log/slog"
	"os"
	"time"

	"civilos/backend/internal/models"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func InitDB() {
	var err error

	host := getEnv("DB_HOST", "localhost")
	port := getEnv("DB_PORT", "5432")
	user := getEnv("DB_USER", "civilos")
	password := getEnv("DB_PASSWORD", "civilos")
	dbname := getEnv("DB_NAME", "civilos")
	sslmode := getEnv("DB_SSL", "disable")

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=%s TimeZone=UTC",
		host, user, password, dbname, port, sslmode)

	DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{
		PrepareStmt:            true,
		SkipDefaultTransaction: true,
		QueryFields:            true,
	})
	if err != nil {
		slog.Error("failed to connect to database", slog.String("error", err.Error()))
		os.Exit(1)
	}

	sqlDB, err := DB.DB()
	if err == nil {
		sqlDB.SetMaxOpenConns(100)
		sqlDB.SetMaxIdleConns(20)
		sqlDB.SetConnMaxLifetime(time.Hour)
		sqlDB.SetConnMaxIdleTime(30 * time.Minute)
	} else {
		slog.Warn("failed to fetch raw SQL DB connection", slog.String("error", err.Error()))
	}

	slog.Info("database connection established")

	// Auto Migration
	err = DB.AutoMigrate(
		&models.Tenant{},
		&models.GlobalAnnouncement{},
		&models.User{},
		&models.Project{},
		&models.BOQItem{},
		&models.Document{},
		&models.Inspection{},
		&models.Checklist{},
		&models.DailyDiaryEntry{},
		&models.MarketplaceListing{},
		&models.B2BPartner{},
		&models.Tender{},
		&models.TenderClient{},
		&models.TenderDetail{},
		&models.TenderLocation{},
		&models.TenderScope{},
		&models.TenderWorkDetail{},
		&models.TenderEligibility{},
		&models.TenderDates{},
		&models.TenderTracking{},
		&models.TenderBOQ{},
		&models.TenderDocument{},
		&models.Invoice{},
		&models.Payment{},
		&models.InventoryItem{},
		&models.MaterialTransaction{},
		&models.Message{},
		&models.Machinery{},
		&models.MachineryLog{},
		&models.LaborWorker{},
		&models.AttendanceLog{},
		&models.PayrollRecord{},
		&models.Expense{},
		&models.PurchaseOrder{},
		&models.WorkOrder{},
		&models.Notification{},
		&models.SystemAuditLog{},
		&models.SubscriptionPlan{},
		&models.TenantSubscription{},
		&models.SupportTicket{},
		&models.TicketMessage{},
		&models.GroupMessage{},
		// Phase 7 additions
		&models.VendorRating{},
		&models.Vendor{},
		&models.Task{},
	)
	if err != nil {
		slog.Error("failed to run database migrations", slog.String("error", err.Error()))
		os.Exit(1)
	}

	slog.Info("auto-migrations completed")

	// Run versioned migrations for schema changes that AutoMigrate cannot handle
	RunMigrations()

	SeedData()
}

func getEnv(key, fallback string) string {
	if val, ok := os.LookupEnv(key); ok {
		return val
	}
	return fallback
}

func SeedData() {
	// Seed Super Admin
	var superAdminCount int64
	DB.Model(&models.User{}).Where("role = ?", "SuperAdmin").Count(&superAdminCount)
	if superAdminCount == 0 {
		hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("Password123"), bcrypt.DefaultCost)
		superAdmin := models.User{
			Name:         "Super Admin",
			Email:        "superadmin@civilos.com",
			PasswordHash: string(hashedPassword),
			Role:         "SuperAdmin",
			TenantID:     nil,
		}
		if err := DB.Create(&superAdmin).Error; err != nil {
			slog.Warn("failed to seed super admin", slog.String("error", err.Error()))
		} else {
			slog.Info("seeded super admin: superadmin@civilos.com / Password123")
		}
	}

	// Seed Acme Tenant if not exists
	var tenantCount int64
	DB.Model(&models.Tenant{}).Where("slug = ?", "acme").Count(&tenantCount)
	if tenantCount == 0 {
		acmeTenant := models.Tenant{
			Name:         "Acme Construction Ltd.",
			Slug:         "acme",
			IsActive:     true,
			FeatureFlags: `{"site_diary": true, "inventory": true, "marketplace": true}`,
		}
		if err := DB.Create(&acmeTenant).Error; err != nil {
			slog.Warn("failed to seed Acme Tenant", slog.String("error", err.Error()))
			return
		}
		slog.Info("seeded tenant: Acme Construction Ltd.")

		// Seed Acme Owner
		hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("Password123"), bcrypt.DefaultCost)
		acmeOwner := models.User{
			Name:         "Acme Owner",
			Email:        "owner@acme.com",
			PasswordHash: string(hashedPassword),
			Role:         "ContractorOwner",
			TenantID:     &acmeTenant.ID,
		}
		DB.Create(&acmeOwner)
		slog.Info("seeded owner: owner@acme.com / Password123")

		// Seed Acme Site Engineer
		acmeEngineer := models.User{
			Name:         "Acme Engineer",
			Email:        "engineer@acme.com",
			PasswordHash: string(hashedPassword),
			Role:         "SiteEngineer",
			TenantID:     &acmeTenant.ID,
		}
		DB.Create(&acmeEngineer)
		slog.Info("seeded engineer: engineer@acme.com / Password123")

		// Seed Acme Projects
		metroProject := models.Project{
			Name:        "Metro Line Extension",
			Description: "Expansion of City Metro Line 3",
			Location:    "Sector 62, Noida",
			TenantID:    acmeTenant.ID,
			BOQItems: []models.BOQItem{
				{
					Description:     "Excavation in all types of soils",
					Unit:            "Cum",
					PlannedQuantity: 5000,
					Rate:            120,
				},
				{
					Description:     "Reinforced Cement Concrete M25 grade",
					Unit:            "Cum",
					PlannedQuantity: 1200,
					Rate:            4500,
				},
				{
					Description:     "TMT Reinforcement Steel Fe500 grade",
					Unit:            "Ton",
					PlannedQuantity: 80,
					Rate:            65000,
				},
			},
		}
		DB.Create(&metroProject)
		slog.Info("seeded project: Metro Line Extension with BOQ items")

		// Seed Marketplace Listings (tied to Acme tenant initially)
		listings := []models.MarketplaceListing{
			{
				TenantID:    acmeTenant.ID,
				Category:    "RentMachinery",
				Title:       "Excavator JCB 3DX for Rent",
				Description: "Includes operator, fuel separate. Dynamic hydraulic hammer attachment available.",
				Quantity:    1,
				Price:       15000,
				Unit:        "Day",
				ContactInfo: "Logistics Desk (Acme) - 9876543210",
				Status:      "Open",
			},
			{
				TenantID:    acmeTenant.ID,
				Category:    "SellExcessCement",
				Title:       "OPC 43 Grade Cement Bags",
				Description: "Stored in dry warehouse. Immediate delivery. Excess from Metro site.",
				Quantity:    200,
				Price:       380,
				Unit:        "Bags",
				ContactInfo: "Acme Store Keeper - 9911223344",
				Status:      "Open",
			},
			{
				TenantID:    acmeTenant.ID,
				Category:    "RentScaffolding",
				Title:       "H-Frame Scaffolding Sets",
				Description: "Premium steel frames. 50 sets available for immediate hire.",
				Quantity:    50,
				Price:       45,
				Unit:        "Set/Month",
				ContactInfo: "Rentals Manager - 9888777666",
				Status:      "Open",
			},
		}
		for _, l := range listings {
			DB.Create(&l)
		}
		slog.Info("seeded marketplace listings")

		// Seed B2BPartners (independent directory)
		partners := []models.B2BPartner{
			{
				Name:        "UltraTech Cement Dealer",
				Type:        "Vendor",
				Services:    "Bulk OPC/PPC Cement supply and delivery",
				Location:    "Industrial Area, Sector 4, Noida",
				ContactInfo: "sales@ultratech-noida.com / 9876500011",
				Rating:      4.8,
			},
			{
				Name:        "VRL Logistics Fleet",
				Type:        "Transporter",
				Services:    "Flatbed trailers, transit mixers, and material shipping logistics",
				Location:    "Transport Nagar, Delhi",
				ContactInfo: "vrl.delhi@vrllogistics.com / 9988776655",
				Rating:      4.5,
			},
			{
				Name:        "Tata BlueScope Steel Ltd",
				Type:        "Vendor",
				Services:    "TMT bars, reinforcement mesh, structural girders",
				Location:    "Kirti Nagar, New Delhi",
				ContactInfo: "delhi@tatabluescope.com / 9911009988",
				Rating:      4.9,
			},
		}
		for _, p := range partners {
			DB.Create(&p)
		}
		slog.Info("seeded B2B partners")

		// Seed Tenders
		tender1 := models.Tender{
			TenantID:    1,
			TenderName:  "City Highway Widening Project",
			TenderType:  "Government",
			Department:  "Public Works Department (PWD)",
			Status:      "Draft",
			CreatedByID: 1,
		}
		DB.Create(&tender1)

		tender2 := models.Tender{
			TenantID:    1,
			TenderName:  "Metro Depot Structural Works",
			TenderType:  "Government",
			Department:  "Metro Rail Corporation",
			Status:      "Draft",
			CreatedByID: 1,
		}
		DB.Create(&tender2)
		slog.Info("seeded active tenders")

		// Seed Invoices & Payments for Acme
		invoice1 := models.Invoice{
			ProjectID:     metroProject.ID,
			InvoiceNumber: "INV-2026-001",
			ClientName:    "Noida Metro Rail Authority",
			IssueDate:     "2026-06-01",
			DueDate:       "2026-07-01",
			TotalAmount:   75000,
			Status:        "Unpaid",
		}
		DB.Create(&invoice1)

		invoice2 := models.Invoice{
			ProjectID:     metroProject.ID,
			InvoiceNumber: "INV-2026-002",
			ClientName:    "Noida Metro Rail Authority",
			IssueDate:     "2026-05-01",
			DueDate:       "2026-06-01",
			TotalAmount:   120000,
			Status:        "Paid",
		}
		DB.Create(&invoice2)

		payment1 := models.Payment{
			InvoiceID:     invoice2.ID,
			Amount:        120000,
			PaymentDate:   "2026-05-25",
			PaymentMethod: "BankTransfer",
			ReferenceNo:   "TXN987654321",
			Notes:         "Full payment for Milestone 1",
		}
		DB.Create(&payment1)
		slog.Info("seeded invoices and payments")

		// Seed Inventory Items
		cementItem := models.InventoryItem{
			TenantID:    acmeTenant.ID,
			ItemName:    "OPC 43 Grade Cement",
			SKU:         "CEM-OPC-043",
			Category:    "Material",
			Unit:        "Bags",
			Quantity:    250,
			SafetyStock: 100,
		}
		DB.Create(&cementItem)

		steelItem := models.InventoryItem{
			TenantID:    acmeTenant.ID,
			ItemName:    "TMT Steel Bars 12mm",
			SKU:         "STL-TMT-012",
			Category:    "Material",
			Unit:        "Tons",
			Quantity:    15,
			SafetyStock: 5,
		}
		DB.Create(&steelItem)

		sandItem := models.InventoryItem{
			TenantID:    acmeTenant.ID,
			ItemName:    "Coarse River Sand",
			SKU:         "SND-CRS-001",
			Category:    "Material",
			Unit:        "Cum",
			Quantity:    80,
			SafetyStock: 50,
		}
		DB.Create(&sandItem)
		slog.Info("seeded warehouse inventory")

		// Seed Material Transactions
		tx1 := models.MaterialTransaction{
			InventoryItemID: cementItem.ID,
			Type:            "IN",
			Quantity:        300,
			Reference:       "PO-10023",
			Notes:           "Initial purchase from dealer",
			TransactionDate: "2026-06-10",
		}
		DB.Create(&tx1)

		tx2 := models.MaterialTransaction{
			InventoryItemID: cementItem.ID,
			Type:            "OUT",
			Quantity:        50,
			Reference:       "PRJ-1",
			Notes:           "Issued to Metro line site",
			TransactionDate: "2026-06-15",
		}
		DB.Create(&tx2)

		tx3 := models.MaterialTransaction{
			InventoryItemID: steelItem.ID,
			Type:            "IN",
			Quantity:        15,
			Reference:       "PO-10024",
			Notes:           "Warehouse stocking",
			TransactionDate: "2026-06-12",
		}
		DB.Create(&tx3)
		slog.Info("seeded material transactions")

		// Seed Machinery Fleet
		excavator := models.Machinery{
			TenantID:      acmeTenant.ID,
			Name:          "CAT 320 Heavy Excavator",
			ModelNumber:   "CAT-320D",
			HourlyRate:    2500,
			TotalHoursRun: 120,
			Status:        "Active",
		}
		DB.Create(&excavator)

		transitMixer := models.Machinery{
			TenantID:      acmeTenant.ID,
			Name:          "Schwing Stetter Transit Mixer",
			ModelNumber:   "AM9SH",
			HourlyRate:    1800,
			TotalHoursRun: 45,
			Status:        "Active",
		}
		DB.Create(&transitMixer)

		macLog1 := models.MachineryLog{
			TenantID:    &acmeTenant.ID,
			MachineryID: excavator.ID,
			Date:        "2026-06-25",
			UsageHours:  6.5,
			FuelEntry:   45.5,
			LoggedByID:  2,
			Notes:       "Excavation at Noida Sector 62 site",
		}
		DB.Create(&macLog1)
		slog.Info("seeded machinery fleet and logs")

		// Seed Labor Workers
		worker1 := models.LaborWorker{
			TenantID:      acmeTenant.ID,
			Name:          "Ram Singh",
			SkillCategory: "Mason",
			DailyRate:     600,
		}
		DB.Create(&worker1)

		worker2 := models.LaborWorker{
			TenantID:      acmeTenant.ID,
			Name:          "Lakhan Lal",
			SkillCategory: "Helper",
			DailyRate:     400,
		}
		DB.Create(&worker2)

		worker3 := models.LaborWorker{
			TenantID:      acmeTenant.ID,
			Name:          "Amit Kumar",
			SkillCategory: "Operator",
			DailyRate:     900,
		}
		DB.Create(&worker3)

		// Seed Attendance Logs
		att1 := models.AttendanceLog{
			LaborWorkerID: worker1.ID,
			Date:          "2026-06-25",
			Status:        "Present",
		}
		DB.Create(&att1)

		att2 := models.AttendanceLog{
			LaborWorkerID: worker2.ID,
			Date:          "2026-06-25",
			Status:        "Overtime",
			OvertimeHours: 2,
		}
		DB.Create(&att2)

		att3 := models.AttendanceLog{
			LaborWorkerID: worker3.ID,
			Date:          "2026-06-25",
			Status:        "Absent",
		}
		DB.Create(&att3)

		// Seed Payroll Records
		pay1 := models.PayrollRecord{
			LaborWorkerID: worker1.ID,
			Month:         "2026-06",
			WagesEarned:   18000,
			Status:        "Paid",
		}
		DB.Create(&pay1)

		pay2 := models.PayrollRecord{
			LaborWorkerID: worker2.ID,
			Month:         "2026-06",
			WagesEarned:   12000,
			Status:        "Unpaid",
		}
		DB.Create(&pay2)
		slog.Info("seeded labor force, attendance and payroll")

		// Seed Chat Messages
		msg1 := models.Message{
			SenderID:   1,
			ReceiverID: 2,
			Content:    "Welcome to CivilOS! Let us know if you need to enable any specific B2B features.",
			CreatedAt:  time.Now().Add(-2 * time.Hour),
		}
		DB.Create(&msg1)

		msg2 := models.Message{
			SenderID:   2,
			ReceiverID: 1,
			Content:    "Thanks, Super Admin! We are currently testing the warehouse inventory module.",
			CreatedAt:  time.Now().Add(-1 * time.Hour),
		}
		DB.Create(&msg2)
		slog.Info("seeded chat messages")
	}
}
