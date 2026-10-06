package main

import (
	"civilos/backend/internal/modules/admin"
	"civilos/backend/internal/modules/ai"
	"civilos/backend/internal/modules/auth"
	"civilos/backend/internal/modules/chat"
	"civilos/backend/internal/modules/documents"
	"civilos/backend/internal/modules/finance"
	"civilos/backend/internal/modules/inventory"
	"civilos/backend/internal/modules/labor"
	"civilos/backend/internal/modules/machinery"
	"civilos/backend/internal/modules/mapping"
	"civilos/backend/internal/modules/marketplace"
	"civilos/backend/internal/modules/notifications"
	"civilos/backend/internal/modules/projects"
	"civilos/backend/internal/modules/reports"
	"civilos/backend/internal/modules/search"
	"civilos/backend/internal/modules/tasks"
	"log/slog"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"civilos/backend/internal/core"
	"civilos/backend/internal/db"

	"civilos/backend/internal/middleware"
	"civilos/backend/internal/ws"

	"github.com/gofiber/contrib/websocket"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/compress"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/joho/godotenv"
)

func main() {
	// Configure structured JSON logging
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	})))

	// Load environment variables if .env file exists
	if err := godotenv.Load(); err != nil {
		slog.Warn("No .env file found, relying on environment variables")
	}

	// Production security safeguard for JWT secret
	if os.Getenv("APP_ENV") == "production" {
		secret := os.Getenv("JWT_SECRET")
		if secret == "" || secret == "civilos_secret_key_change_me_in_production" {
			slog.Error("JWT_SECRET environment variable is missing or insecure default is set in production environment!")
			os.Exit(1)
		}
	}

	// Initialize Database
	db.InitDB()

	// Initialize Redis Cache
	core.InitCache()

	// Create Fiber App with payload limit protection
	app := fiber.New(fiber.Config{
		AppName:   "CivilOS Core API v1.0",
		BodyLimit: 4 * 1024 * 1024, // 4MB maximum payload size limit
	})

	// Request ID for tracing (must come first)
	app.Use(middleware.RequestID())

	// Structured JSON request logging
	app.Use(middleware.StructuredLogger())

	// Apply standard security headers globally
	app.Use(middleware.SecurityHeaders())

	// Apply global rate limiting (100 requests / minute)
	app.Use(middleware.GlobalLimiter())

	// Enable gzip compression
	app.Use(compress.New(compress.Config{
		Level: compress.LevelBestSpeed,
	}))

	// Configure CORS dynamically to support localhost development with credentials
	app.Use(cors.New(cors.Config{
		AllowOriginsFunc: func(origin string) bool {
			return strings.HasPrefix(origin, "http://localhost") || strings.HasPrefix(origin, "https://localhost")
		},
		AllowHeaders:     "Origin, Content-Type, Accept, Authorization, Tenant-ID, X-Request-ID",
		AllowMethods:     "GET, POST, PUT, DELETE, OPTIONS",
		ExposeHeaders:    "Content-Length, X-Request-ID",
		AllowCredentials: true,
	}))

	// API Route Group (versioned)
	api := app.Group("/api/v1")

	// Public Auth Routes (protected by a strict rate limiter)

	// Protected Routes (JWT required)
	protectedGroup := api.Group("", middleware.AuthRequired)

	// Tenant-isolated space (JWT and Tenant details required)
	tenantGroup := protectedGroup.Group("", middleware.TenantScope)

	auth.RegisterRoutes(api, protectedGroup, tenantGroup)
	protectedGroup.Post("/users/me/location", auth.UpdateLocation)

	// --- Projects ---
	tenantGroup.Get("/projects", projects.ListProjects)
	tenantGroup.Get("/projects/:projectId", projects.GetProject)
	tenantGroup.Post("/projects", middleware.RequireRoles("Contractor"), projects.CreateProject)
	tenantGroup.Put("/projects/:projectId", middleware.RequireRoles("Contractor"), projects.UpdateProject)
	tenantGroup.Delete("/projects/:projectId", middleware.RequireRoles("Contractor"), projects.DeleteProject)

	// Supervisor Assignments & Tracking
	tenantGroup.Post("/projects/:id/assign", middleware.RequireRoles("Contractor"), projects.AssignSupervisor)
	tenantGroup.Delete("/projects/:id/assignments/:assignment_id", middleware.RequireRoles("Contractor"), projects.RemoveSupervisor)

	// --- Supervisor Live Tracking ---
	tenantGroup.Post("/location/ping", middleware.RequireRoles("Supervisor"), projects.PingSupervisorLocation)
	tenantGroup.Get("/location/supervisors", middleware.RequireRoles("Contractor"), projects.GetLiveSupervisorLocations)

	tenantGroup.Get("/issues", middleware.RequireRoles("Contractor", "Supervisor"), projects.ListSiteIssues)
	tenantGroup.Post("/issues", middleware.RequireRoles("Supervisor"), projects.CreateSiteIssue)

	tenantGroup.Get("/projects/:projectId/diaries", projects.ListDiaries)
	tenantGroup.Post("/projects/:projectId/diaries", middleware.RequireRoles("Contractor"), projects.SubmitDiary)
	tenantGroup.Put("/projects/:projectId/diaries/:id", middleware.RequireRoles("Contractor"), projects.UpdateDiary)
	tenantGroup.Delete("/projects/:projectId/diaries/:id", middleware.RequireRoles("Contractor"), projects.DeleteDiary)
	tenantGroup.Post("/projects/:projectId/boq/import", middleware.RequireRoles("Contractor"), projects.ImportBOQ)
	tenantGroup.Get("/projects/:projectId/stats", projects.GetProjectStats)

	// --- Dashboard Stats ---
	tenantGroup.Get("/dashboard/stats", projects.GetDashboardStats)

	// --- Diary ---
	tenantGroup.Post("/diaries/:id/approve", middleware.RequireRoles("Contractor"), projects.ApproveDiary)

	// --- B2B Marketplace & Partners ---
	tenantGroup.Get("/marketplace", marketplace.ListMarketplaceListings)
	tenantGroup.Post("/marketplace", middleware.RequireRoles("Contractor"), marketplace.CreateMarketplaceListing)
	tenantGroup.Put("/marketplace/:id", middleware.RequireRoles("Contractor"), marketplace.UpdateMarketplaceListing)
	tenantGroup.Delete("/marketplace/:id", middleware.RequireRoles("Contractor"), marketplace.DeleteMarketplaceListing)
	tenantGroup.Get("/marketplace/partners", middleware.RequireRoles("Contractor"), marketplace.ListB2BPartners)
	tenantGroup.Post("/marketplace/partners", middleware.RequireRoles("Contractor"), marketplace.CreateB2BPartner)
	tenantGroup.Put("/marketplace/partners/:id", middleware.RequireRoles("Contractor"), marketplace.UpdateB2BPartner)
	tenantGroup.Delete("/marketplace/partners/:id", middleware.RequireRoles("Contractor"), marketplace.DeleteB2BPartner)

	// --- Tenders & Bids ---
	tenantGroup.Get("/tenders", marketplace.ListTenders)
	tenantGroup.Get("/tenders/:id", marketplace.GetTender)
	tenantGroup.Post("/tenders", middleware.RequireRoles("SuperAdmin", "Contractor"), marketplace.CreateTender)
	tenantGroup.Post("/tenders/import-pdf", middleware.RequireRoles("SuperAdmin", "Contractor"), marketplace.ImportTenderPDF)

	// --- Vendor Management (Contractor) ---
	tenantGroup.Get("/vendors", middleware.RequireRoles("Contractor"), marketplace.ListAllPlatformVendors)
	tenantGroup.Get("/my-vendors", middleware.RequireRoles("Contractor"), marketplace.GetContractorVendors)
	tenantGroup.Put("/my-vendors/:vendorId", middleware.RequireRoles("Contractor"), marketplace.UpdateVendorRelation)

	// --- Advanced PO Actions ---
	tenantGroup.Post("/pos/:id/duplicate", middleware.RequireRoles("Contractor"), marketplace.ContractorDuplicatePO)
	tenantGroup.Post("/pos/:id/cancel", middleware.RequireRoles("Contractor"), marketplace.ContractorCancelPO)

	// --- Vendor Portal ---
	tenantGroup.Get("/vendor/purchase-orders", middleware.RequireRoles("Vendor"), marketplace.ListVendorPOs)
	tenantGroup.Put("/vendor/purchase-orders/:id/status", middleware.RequireRoles("Vendor"), marketplace.UpdatePOStatus)
	tenantGroup.Post("/vendor/purchase-orders/:id/invoice", middleware.RequireRoles("Vendor"), marketplace.SubmitInvoice)

	// --- Vendor Profile ---
	tenantGroup.Get("/vendor/profile", middleware.RequireRoles("Vendor"), marketplace.GetVendorProfile)
	tenantGroup.Put("/vendor/profile", middleware.RequireRoles("Vendor"), marketplace.UpdateVendorProfile)

	// --- PO Actions ---
	tenantGroup.Put("/purchase-orders/:id/verify", middleware.RequireRoles("Supervisor"), marketplace.SupervisorVerifyPO)
	tenantGroup.Put("/purchase-orders/:id/confirm", middleware.RequireRoles("Contractor"), marketplace.ContractorConfirmPO)

	// --- Billing & Invoicing ---
	tenantGroup.Get("/invoices", finance.ListInvoices)
	tenantGroup.Post("/invoices", middleware.RequireRoles("Contractor"), finance.CreateInvoice)
	tenantGroup.Put("/invoices/:id", middleware.RequireRoles("Contractor"), finance.UpdateInvoice)
	tenantGroup.Post("/invoices/:id/payments", middleware.RequireRoles("Contractor"), finance.RecordPayment)

	// --- Inventory & Warehouse ---
	tenantGroup.Get("/inventory", inventory.ListInventory)
	tenantGroup.Post("/inventory", middleware.RequireRoles("Contractor"), inventory.CreateInventoryItem)
	tenantGroup.Put("/inventory/:id", middleware.RequireRoles("Contractor"), inventory.UpdateInventoryItem)
	tenantGroup.Delete("/inventory/:id", middleware.RequireRoles("Contractor"), inventory.DeleteInventoryItem)
	tenantGroup.Post("/inventory/transactions", middleware.RequireRoles("Contractor"), inventory.RecordTransaction)

	// --- Fleet & Machinery ---
	tenantGroup.Get("/machinery", machinery.ListMachinery)
	tenantGroup.Post("/machinery", middleware.RequireRoles("Contractor"), machinery.CreateMachinery)
	tenantGroup.Put("/machinery/:id", middleware.RequireRoles("Contractor"), machinery.UpdateMachinery)
	tenantGroup.Delete("/machinery/:id", middleware.RequireRoles("Contractor"), machinery.DeleteMachinery)
	tenantGroup.Post("/machinery/:id/logs", middleware.RequireRoles("Contractor"), machinery.RecordMachineryLog)

	// --- Labor & Payroll ---
	tenantGroup.Get("/labor", labor.ListWorkers)
	tenantGroup.Post("/labor", middleware.RequireRoles("Contractor"), labor.CreateWorker)
	tenantGroup.Put("/labor/:id", middleware.RequireRoles("Contractor"), labor.UpdateWorker)
	tenantGroup.Delete("/labor/:id", middleware.RequireRoles("Contractor"), labor.DeleteWorker)

	// --- Documents ---
	tenantGroup.Get("/documents", documents.GetDocuments)
	tenantGroup.Post("/documents", middleware.RequireRoles("Contractor"), documents.UploadDocument)
	tenantGroup.Delete("/documents/:id", middleware.RequireRoles("Contractor"), documents.DeleteDocument)

	// --- Uploads ---
	tenantGroup.Post("/upload", middleware.RequireRoles("Contractor"), documents.UploadFile)

	// --- AI Assistant / Processing ---
	tenantGroup.Post("/ai/ocr", middleware.RequireRoles("Contractor"), ai.OCRExtract)
	tenantGroup.Post("/ai/transcribe", middleware.RequireRoles("Contractor"), ai.TranscribeDiary)
	tenantGroup.Get("/projects/:id/estimation", middleware.RequireRoles("Contractor"), ai.PredictMaterialEstimation)
	tenantGroup.Post("/ai/chat", middleware.RequireRoles("Contractor"), ai.Chatbot)

	// --- Reports ---
	tenantGroup.Get("/reports/cost", reports.GetCostReport)
	tenantGroup.Get("/reports/labor", reports.GetLaborReport)
	tenantGroup.Get("/reports/machinery", reports.GetMachineryReport)

	// --- Map ---
	tenantGroup.Get("/map/projects", mapping.GetMapData)

	// --- Export / Download ---
	tenantGroup.Get("/export/expenses/csv", finance.ExportExpensesCSV)
	tenantGroup.Get("/export/labor/csv", finance.ExportLaborCSV)
	tenantGroup.Get("/export/inventory/csv", finance.ExportInventoryCSV)
	tenantGroup.Get("/export/invoices/:id/pdf", finance.ExportInvoicePDF)

	// --- Inspections & Checklists ---
	tenantGroup.Get("/inspections", tasks.ListInspections)
	tenantGroup.Post("/inspections", middleware.RequireRoles("Contractor"), tasks.CreateInspection)
	tenantGroup.Delete("/inspections/:id", middleware.RequireRoles("Contractor"), tasks.DeleteInspection)

	tenantGroup.Get("/checklists", tasks.ListChecklists)
	tenantGroup.Post("/checklists", middleware.RequireRoles("Contractor"), tasks.CreateChecklist)
	tenantGroup.Put("/checklists/:id/toggle", middleware.RequireRoles("Contractor"), tasks.ToggleChecklist)
	tenantGroup.Delete("/checklists/:id", middleware.RequireRoles("Contractor"), tasks.DeleteChecklist)
	tenantGroup.Post("/labor/attendance", middleware.RequireRoles("Contractor"), labor.RecordAttendance)
	tenantGroup.Get("/labor/payroll", labor.ListPayroll)
	tenantGroup.Put("/labor/payroll/:id/pay", middleware.RequireRoles("Contractor"), labor.MarkPayrollPaid)

	// --- User Management ---

	// --- Expense Management ---
	tenantGroup.Get("/expenses", middleware.RequireRoles("Contractor"), finance.ListExpenses)
	tenantGroup.Post("/expenses", middleware.RequireRoles("Contractor"), finance.CreateExpense)
	tenantGroup.Delete("/expenses/:id", middleware.RequireRoles("Contractor"), finance.DeleteExpense)
	tenantGroup.Put("/expenses/:id", middleware.RequireRoles("Contractor"), finance.UpdateExpense)

	// --- Purchase Orders ---
	tenantGroup.Get("/purchase-orders", tasks.ListPurchaseOrders)
	tenantGroup.Post("/purchase-orders", middleware.RequireRoles("Contractor"), tasks.CreatePurchaseOrder)
	tenantGroup.Put("/purchase-orders/:id/status", middleware.RequireRoles("Contractor"), tasks.UpdatePurchaseOrderStatus)
	tenantGroup.Delete("/purchase-orders/:id", middleware.RequireRoles("Contractor"), tasks.DeletePurchaseOrder)

	// --- Work Orders ---
	tenantGroup.Get("/work-orders", tasks.ListWorkOrders)
	tenantGroup.Post("/work-orders", middleware.RequireRoles("Contractor"), tasks.CreateWorkOrder)
	tenantGroup.Put("/work-orders/:id/status", middleware.RequireRoles("Contractor"), tasks.UpdateWorkOrderStatus)
	tenantGroup.Delete("/work-orders/:id", middleware.RequireRoles("Contractor"), tasks.DeleteWorkOrder)

	// --- Gantt / Project Tasks ---
	tenantGroup.Get("/tasks", tasks.ListTasks)
	tenantGroup.Post("/tasks", middleware.RequireRoles("Contractor"), tasks.CreateTask)
	tenantGroup.Put("/tasks/:id", middleware.RequireRoles("Contractor"), tasks.UpdateTask)
	tenantGroup.Delete("/tasks/:id", middleware.RequireRoles("Contractor"), tasks.DeleteTask)
	tenantGroup.Put("/tasks/reorder", middleware.RequireRoles("Contractor"), tasks.ReorderTasks)

	// --- Notifications ---
	tenantGroup.Get("/notifications", notifications.ListNotifications)
	tenantGroup.Put("/notifications/:id/read", notifications.MarkNotificationRead)
	tenantGroup.Delete("/notifications/:id", notifications.DeleteNotification)

	// --- Support Tickets ---
	tenantGroup.Get("/support/tickets", admin.ListMyTickets)
	tenantGroup.Post("/support/tickets", admin.CreateTicket)
	tenantGroup.Post("/support/feedback", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"message": "Feedback received"})
	})

	// --- Global Search ---
	tenantGroup.Get("/search", search.GlobalSearch)

	// --- Vendor Ratings ---
	api.Get("/marketplace/vendors/:id/ratings", marketplace.GetVendorRatings)
	tenantGroup.Post("/marketplace/vendors/:id/ratings", marketplace.CreateVendorRating)

	// --- Material Price History ---
	tenantGroup.Get("/inventory/price-history", inventory.GetPriceHistory)

	// --- Audit Logs (personal) ---
	protectedGroup.Get("/audit-logs/me", func(c *fiber.Ctx) error {
		return admin.GetMyAuditLogs(c)
	})

	// --- B2B Messaging / Chat (1-on-1) ---
	protectedGroup.Post("/chat", chat.SendMessage)
	protectedGroup.Get("/chat/:receiverId", chat.ListMessages)

	// --- WebSocket Chat ---
	protectedGroup.Get("/ws/chat", ws.AuthWS, websocket.New(ws.HandleWebSocket))
	protectedGroup.Get("/announcements", admin.GetAnnouncements)

	// --- B2B Global Group Chat (ContractorOwner + SuperAdmin only) ---
	groupChatGroup := protectedGroup.Group("/group-chat", middleware.RequireRoles("Contractor", "SuperAdmin"))
	groupChatGroup.Get("/", chat.GetGroupMessages)
	groupChatGroup.Post("/", chat.SendGroupMessage)

	// --- Super Admin Space (Only SuperAdmin role) ---
	adminGroup := protectedGroup.Group("/admin", middleware.RequireRoles("SuperAdmin"))
	adminGroup.Get("/tenants", admin.ListTenants)
	adminGroup.Post("/tenants/:id/features", admin.ToggleTenantFeatures)
	adminGroup.Put("/tenants/:id/status", admin.SetTenantStatus)
	adminGroup.Get("/analytics", admin.GetGlobalAnalytics)
	adminGroup.Get("/health", admin.GetSystemHealth)
	adminGroup.Get("/audit-logs", admin.GetAuditLogs)
	adminGroup.Post("/announcements", admin.CreateAnnouncement)
	adminGroup.Post("/tenants/:id/impersonate", admin.ImpersonateTenant)
	adminGroup.Post("/tenants/:id/checkout", finance.GeneratePaymentLink)
	adminGroup.Get("/users", admin.GetGlobalUsers)
	adminGroup.Get("/tickets", admin.ListAllTickets)

	// Vendor Verification
	adminGroup.Get("/vendors", admin.ListGlobalVendors)
	adminGroup.Put("/vendors/:id/status", admin.SetVendorVerificationStatus)

	// Platform Settings
	adminGroup.Get("/settings", admin.ListPlatformSettings)
	adminGroup.Put("/settings", admin.UpdatePlatformSetting)

	// Webhooks
	app.Post("/webhooks/razorpay", finance.RazorpayWebhook)

	// Health Check
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.Status(200).JSON(fiber.Map{
			"status":  "running",
			"service": "CivilOS Core API",
			"version": "v1.0",
		})
	})

	// Serve Frontend Web App
	// Serve uploaded files statically (protected)
	app.Use("/uploads", middleware.AuthRequired)
	app.Static("/uploads", "./uploads")
	app.Static("/", "./web")

	// Fallback to index.html for SPA routing
	app.Use(func(c *fiber.Ctx) error {
		// Only fallback for non-API routes
		if !strings.HasPrefix(c.Path(), "/api/") {
			return c.SendFile("./web/index.html")
		}
		return c.Next()
	})

	// Get Port from env
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	slog.Info("starting server", slog.String("port", port))
	go func() {
		if err := app.Listen(":" + port); err != nil {
			slog.Error("server startup failed", slog.String("error", err.Error()))
		}
	}()

	// Graceful Shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
	<-quit
	slog.Info("gracefully shutting down server...")

	if err := app.Shutdown(); err != nil {
		slog.Error("server shutdown failed", slog.String("error", err.Error()))
	}
	slog.Info("server exited")
}
