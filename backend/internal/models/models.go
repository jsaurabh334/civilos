package models

import (
	"time"

	"gorm.io/gorm"
)

type Tenant struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	Name      string         `gorm:"not null" json:"name"`
	Slug      string         `gorm:"uniqueIndex;not null" json:"slug"`
	IsActive  bool           `gorm:"default:true" json:"is_active"`
	CreatedAt time.Time      `json:"created_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
	UpdatedAt time.Time      `json:"updated_at"`

	// JSON string for feature flags, e.g. {"site_diary": true, "inventory": false}
	FeatureFlags string `gorm:"default:'{}'" json:"feature_flags"`

	// Subscriptions
	ActiveSubscription *TenantSubscription `gorm:"foreignKey:TenantID" json:"active_subscription,omitempty"`
}

type ContractorVendorRelation struct {
	ID         uint `gorm:"primaryKey" json:"id"`
	TenantID   uint `gorm:"not null;index:idx_tenant_vendor" json:"tenant_id"`
	VendorID   uint `gorm:"not null;index:idx_tenant_vendor" json:"vendor_id"`
	Vendor     User `gorm:"foreignKey:VendorID" json:"vendor,omitempty"`
	IsFavorite bool `gorm:"default:false" json:"is_favorite"`
	IsBlocked  bool `gorm:"default:false" json:"is_blocked"`
	Rating     int  `gorm:"default:0" json:"rating"` // 1-5 stars
}

type PlatformSetting struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Key       string    `gorm:"uniqueIndex;not null" json:"key"`
	Value     string    `gorm:"not null" json:"value"`
	UpdatedAt time.Time `json:"updated_at"`
}

type SubscriptionPlan struct {
	ID              uint           `gorm:"primaryKey" json:"id"`
	Name            string         `gorm:"not null;unique" json:"name"`
	PricePerMonth   float64        `gorm:"not null" json:"price_per_month"`
	AllowedFeatures string         `gorm:"default:'{}'" json:"allowed_features"` // JSON
	CreatedAt       time.Time      `json:"created_at"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

type TenantSubscription struct {
	ID                 uint             `gorm:"primaryKey" json:"id"`
	TenantID           uint             `gorm:"not null;uniqueIndex" json:"tenant_id"`
	PlanID             uint             `gorm:"not null" json:"plan_id"`
	Plan               SubscriptionPlan `gorm:"constraint:OnUpdate:CASCADE,OnDelete:RESTRICT;" json:"plan,omitempty"`
	Status             string           `gorm:"not null;default:'active'" json:"status"` // active, past_due, canceled
	StripeSubscription string           `json:"stripe_subscription_id"`
	CurrentPeriodEnd   time.Time        `json:"current_period_end"`
	CreatedAt          time.Time        `json:"created_at"`
	DeletedAt          gorm.DeletedAt   `gorm:"index" json:"deleted_at,omitempty"`
	UpdatedAt          time.Time        `json:"updated_at"`
}

type User struct {
	ID                  uint           `gorm:"primaryKey" json:"id"`
	Name                string         `gorm:"not null" json:"name"`
	Email               string         `gorm:"uniqueIndex;not null" json:"email"`
	Phone               string         `json:"phone"`
	AvatarURL           string         `json:"avatar_url"`
	PasswordHash        string         `gorm:"not null" json:"-"`
	VerificationStatus  string         `gorm:"default:'Pending'" json:"verification_status"` // Pending, Verified, Suspended, Blacklisted (For Vendors)
	Role                string         `gorm:"not null" json:"role"`                         // SuperAdmin, Contractor, Supervisor, Vendor
	TenantID            *uint          `gorm:"index" json:"tenant_id,omitempty"`             // Nullable for SuperAdmin
	Tenant              *Tenant        `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"tenant,omitempty"`
	CreatedAt           time.Time      `json:"created_at"`
	DeletedAt           gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
	UpdatedAt           time.Time      `json:"updated_at"`
	PasswordResetToken  string         `gorm:"default:null" json:"password_reset_token,omitempty"`
	PasswordResetExpiry *time.Time     `gorm:"default:null" json:"password_reset_expiry,omitempty"`
	FCMToken            string         `gorm:"default:null" json:"fcm_token,omitempty"`
	TwoFactorEnabled    bool           `gorm:"default:false" json:"two_factor_enabled"`
	TwoFactorSecret     string         `json:"-"`

	// Live Location Tracking (primarily for Supervisors)
	LastLatitude       float64    `gorm:"default:0" json:"last_latitude"`
	LastLongitude      float64    `gorm:"default:0" json:"last_longitude"`
	LastLocationUpdate *time.Time `json:"last_location_update,omitempty"`

	// Security & Auth
	FailedLoginAttempts int        `gorm:"default:0" json:"failed_login_attempts"`
	LockedUntil         *time.Time `gorm:"default:null" json:"locked_until,omitempty"`
}

type SupervisorLocation struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	TenantID     uint      `gorm:"not null;index" json:"tenant_id"`
	SupervisorID uint      `gorm:"not null;index" json:"supervisor_id"`
	Supervisor   User      `gorm:"foreignKey:SupervisorID" json:"supervisor,omitempty"`
	Latitude     float64   `gorm:"not null" json:"latitude"`
	Longitude    float64   `gorm:"not null" json:"longitude"`
	Accuracy     float64   `json:"accuracy"`
	Timestamp    time.Time `gorm:"not null;index" json:"timestamp"`
}

type ProjectAssignment struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	ProjectID uint           `gorm:"not null;index" json:"project_id"`
	UserID    uint           `gorm:"not null;index" json:"user_id"`
	Project   Project        `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"project"`
	User      User           `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"user"`
	StartDate *string        `json:"start_date,omitempty"` // stored as YYYY-MM-DD
	EndDate   *string        `json:"end_date,omitempty"`   // stored as YYYY-MM-DD
	CreatedAt time.Time      `json:"created_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

type SupportTicket struct {
	ID          uint           `gorm:"primaryKey" json:"id"`
	TenantID    uint           `gorm:"not null;index" json:"tenant_id"`
	UserID      uint           `gorm:"not null;index" json:"user_id"`
	Subject     string         `gorm:"not null" json:"subject"`
	Description string         `gorm:"not null" json:"description"`
	Status      string         `gorm:"not null;default:'Open';index" json:"status"`     // Open, In Progress, Resolved
	Priority    string         `gorm:"not null;default:'Medium';index" json:"priority"` // Low, Medium, High, Critical
	CreatedAt   time.Time      `json:"created_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
	UpdatedAt   time.Time      `json:"updated_at"`
}

type TicketMessage struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	TicketID  uint           `gorm:"not null;index" json:"ticket_id"`
	SenderID  uint           `gorm:"not null;index" json:"sender_id"` // UserID of the person replying (can be admin or tenant user)
	Message   string         `gorm:"not null" json:"message"`
	CreatedAt time.Time      `json:"created_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

// GroupMessage is the global B2B cross-tenant chat room
type GroupMessage struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	SenderID  uint           `gorm:"not null;index" json:"sender_id"`
	Sender    User           `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"sender"`
	Content   string         `gorm:"not null" json:"content"`
	CreatedAt time.Time      `json:"created_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

type Project struct {
	ID            uint           `gorm:"primaryKey" json:"id"`
	Name          string         `gorm:"not null" json:"name"`
	Description   string         `json:"description"`
	Location      string         `json:"location"`
	Latitude      float64        `gorm:"default:0" json:"latitude"`
	Longitude     float64        `gorm:"default:0" json:"longitude"`
	ProjectType   string         `gorm:"default:'Private'" json:"project_type"` // Private or Government
	TenderNo      string         `json:"tender_no,omitempty"`
	TenderDetails string         `json:"tender_details,omitempty"`
	Status        string         `gorm:"default:'Active';index" json:"status"`
	Budget        float64        `json:"budget"`
	TenantID      uint           `gorm:"not null;index" json:"tenant_id"`
	Tenant        Tenant         `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"-"`
	BOQItems      []BOQItem      `gorm:"foreignKey:ProjectID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"boq_items"`
	CreatedByID   *uint          `json:"created_by_id,omitempty"`
	UpdatedByID   *uint          `json:"updated_by_id,omitempty"`
	CreatedAt     time.Time      `json:"created_at"`
	DeletedAt     gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
	UpdatedAt     time.Time      `json:"updated_at"`
}

type BOQItem struct {
	ID              uint    `gorm:"primaryKey" json:"id"`
	ProjectID       uint    `gorm:"not null;index" json:"project_id"`
	Description     string  `gorm:"not null" json:"description"`
	Unit            string  `gorm:"not null" json:"unit"` // e.g. Cum, Sqm, Kg, Ton
	PlannedQuantity float64 `gorm:"not null" json:"planned_quantity"`
	Rate            float64 `gorm:"not null" json:"rate"`
}

type DailyDiaryEntry struct {
	ID            uint    `gorm:"primaryKey" json:"id"`
	ProjectID     uint    `gorm:"not null;index:idx_project_date" json:"project_id"`
	Project       Project `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"project,omitempty"`
	SupervisorID  uint    `json:"supervisor_id"`
	Supervisor    User    `gorm:"foreignKey:SupervisorID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"supervisor,omitempty"`
	Date          string  `gorm:"not null;index:idx_project_date" json:"date"` // YYYY-MM-DD
	Weather       string  `json:"weather"`
	LaborStrength int     `json:"labor_strength"`
	CompletedWork string  `json:"completed_work"`
	ImageURLs     string  `gorm:"default:'[]'" json:"image_urls"` // JSON array of strings
	Approved      bool    `gorm:"default:false" json:"approved"`
	Latitude      float64 `gorm:"default:0" json:"latitude"`
	Longitude     float64 `gorm:"default:0" json:"longitude"`

	// Phase 4 added fields
	Notes      string `json:"notes"`
	DelayNotes string `json:"delay_notes"`
	PhotoURLs  string `json:"photo_urls"`
	VideoURLs  string `json:"video_urls"`
	VoiceURLs  string `json:"voice_urls"`

	CreatedByID uint           `json:"created_by_id"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

type VendorProduct struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	VendorID     uint      `gorm:"not null;index" json:"vendor_id"`
	Vendor       User      `gorm:"foreignKey:VendorID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"vendor,omitempty"`
	Category     string    `gorm:"not null;index" json:"category"`
	Name         string    `gorm:"not null" json:"name"`
	Description  string    `json:"description"`
	UnitPrice    float64   `gorm:"not null" json:"unit_price"`
	Unit         string    `gorm:"not null" json:"unit"` // e.g., Tons, Liters, Bags
	Availability bool      `gorm:"default:true" json:"availability"`
	CreatedAt    time.Time `json:"created_at"`
}

// VendorRating stores contractor reviews for marketplace vendors
type VendorRating struct {
	ID         uint      `gorm:"primaryKey" json:"id"`
	VendorID   uint      `gorm:"not null;index" json:"vendor_id"`
	ReviewerID uint      `gorm:"not null;index" json:"reviewer_id"`
	TenantID   uint      `gorm:"not null;index" json:"tenant_id"`
	Rating     int       `gorm:"not null;check:rating >= 1 AND rating <= 5" json:"rating"` // 1-5
	Comment    string    `json:"comment"`
	Reviewer   *User     `gorm:"foreignKey:ReviewerID" json:"reviewer,omitempty"`
	CreatedAt  time.Time `json:"created_at"`
}

// Vendor is a marketplace-level vendor entity (separate from User with Vendor role)
type Vendor struct {
	ID          uint           `gorm:"primaryKey" json:"id"`
	CompanyName string         `gorm:"not null;index" json:"company_name"`
	Category    string         `gorm:"not null;index" json:"category"`
	City        string         `json:"city"`
	Phone       string         `json:"phone"`
	Email       string         `json:"email"`
	GST         string         `json:"gst"`
	IsVerified  bool           `gorm:"default:false" json:"is_verified"`
	CreatedAt   time.Time      `json:"created_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

// Task is a generic work task (used by work orders module)
type Task struct {
	ID          uint           `gorm:"primaryKey" json:"id"`
	TenantID    uint           `gorm:"not null;index" json:"tenant_id"`
	ProjectID   *uint          `gorm:"index" json:"project_id,omitempty"`
	AssignedTo  *uint          `gorm:"index" json:"assigned_to,omitempty"`
	Title       string         `gorm:"not null" json:"title"`
	Description string         `json:"description"`
	Status      string         `gorm:"default:'pending';index" json:"status"`
	Priority    string         `gorm:"default:'medium'" json:"priority"`
	DueDate     *time.Time     `json:"due_date,omitempty"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

type MarketplaceListing struct {
	ID          uint           `gorm:"primaryKey" json:"id"`
	TenantID    uint           `gorm:"not null;index" json:"tenant_id"`
	Tenant      Tenant         `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"tenant,omitempty"`
	Category    string         `gorm:"not null;index:idx_category_status" json:"category"` // e.g. BuyMaterial, RentMachinery, HireLabour, HireEngineer, SellScrap, SellExcessCement, SellSteel, RentShuttering, RentScaffolding
	Title       string         `gorm:"not null" json:"title"`
	Description string         `json:"description"`
	Quantity    float64        `json:"quantity"`
	Price       float64        `json:"price"`
	Unit        string         `json:"unit"`
	ContactInfo string         `json:"contact_info"`
	Status      string         `gorm:"default:'Open';index:idx_category_status" json:"status"` // Open, Closed
	CreatedAt   time.Time      `json:"created_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

type B2BPartner struct {
	ID          uint    `gorm:"primaryKey" json:"id"`
	Name        string  `gorm:"not null" json:"name"`
	Type        string  `gorm:"not null;index" json:"type"` // Vendor, Transporter
	Services    string  `json:"services"`                   // Description of supplied materials or logistics routes
	Location    string  `json:"location"`
	ContactInfo string  `json:"contact_info"`
	Rating      float64 `gorm:"default:5.0" json:"rating"`
}

type AuditLog struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	TableName string    `gorm:"not null;index" json:"table_name"`
	RecordID  uint      `gorm:"not null;index" json:"record_id"`
	Action    string    `gorm:"not null" json:"action"` // CREATE, UPDATE, DELETE
	UserID    uint      `gorm:"not null;index" json:"user_id"`
	User      User      `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"user,omitempty"`
	Timestamp time.Time `gorm:"autoCreateTime" json:"timestamp"`
}

// Old Tender and Bid structs moved to tenders.go

type Invoice struct {
	ID             uint           `gorm:"primaryKey" json:"id"`
	ProjectID      uint           `gorm:"not null;index" json:"project_id"`
	Project        Project        `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"project,omitempty"`
	InvoiceNumber  string         `gorm:"uniqueIndex;not null" json:"invoice_number"`
	ClientName     string         `gorm:"not null" json:"client_name"`
	IssueDate      string         `gorm:"not null" json:"issue_date"`                    // YYYY-MM-DD
	DueDate        string         `gorm:"not null;index:idx_tenant_due" json:"due_date"` // YYYY-MM-DD
	TotalAmount    float64        `gorm:"not null" json:"total_amount"`
	TaxAmount      float64        `json:"tax_amount"`
	DiscountAmount float64        `json:"discount_amount"`
	NetTotal       float64        `json:"net_total"`
	Status         string         `gorm:"default:'Unpaid';index:idx_tenant_status" json:"status"` // Unpaid, Paid, Overdue, Cancelled
	Payments       []Payment      `gorm:"foreignKey:InvoiceID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"payments,omitempty"`
	CreatedByID    *uint          `json:"created_by_id,omitempty"`
	UpdatedByID    *uint          `json:"updated_by_id,omitempty"`
	CreatedAt      time.Time      `json:"created_at"`
	DeletedAt      gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
	UpdatedAt      time.Time      `json:"updated_at"`
}

type Payment struct {
	ID            uint           `gorm:"primaryKey" json:"id"`
	InvoiceID     uint           `gorm:"not null;index" json:"invoice_id"`
	Amount        float64        `gorm:"not null" json:"amount"`
	PaymentDate   string         `gorm:"not null" json:"payment_date"` // YYYY-MM-DD
	PaymentMethod string         `json:"payment_method"`               // BankTransfer, Cash, Cheque, UPI
	ReferenceNo   string         `json:"reference_no"`
	Notes         string         `json:"notes"`
	CreatedAt     time.Time      `json:"created_at"`
	DeletedAt     gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

type InventoryItem struct {
	ID          uint           `gorm:"primaryKey" json:"id"`
	TenantID    uint           `gorm:"not null;index" json:"tenant_id"`
	Tenant      Tenant         `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"-"`
	ItemName    string         `gorm:"not null" json:"item_name"`
	SKU         string         `gorm:"index" json:"sku"`
	Barcode     string         `gorm:"index" json:"barcode"`
	Category    string         `json:"category"` // Material, Equipment, Fuel, Consumables
	Unit        string         `gorm:"not null" json:"unit"`
	Quantity    float64        `gorm:"default:0" json:"quantity"`
	SafetyStock float64        `gorm:"default:0" json:"safety_stock"`
	CreatedByID *uint          `json:"created_by_id,omitempty"`
	UpdatedByID *uint          `json:"updated_by_id,omitempty"`
	CreatedAt   time.Time      `json:"created_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
	UpdatedAt   time.Time      `json:"updated_at"`
}

type MaterialTransaction struct {
	ID               uint           `gorm:"primaryKey" json:"id"`
	InventoryItemID  uint           `gorm:"not null;index:idx_item_date" json:"inventory_item_id"`
	InventoryItem    InventoryItem  `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"inventory_item,omitempty"`
	Type             string         `gorm:"not null" json:"type"` // IN, OUT
	Quantity         float64        `gorm:"not null" json:"quantity"`
	Reference        string         `json:"reference"` // Project ID, Purchase Order ID, or Marketplace Buy ID
	Notes            string         `json:"notes"`
	TransactionDate  string         `gorm:"not null;index:idx_item_date" json:"transaction_date"` // YYYY-MM-DD
	EWayBillNumber   string         `json:"eway_bill_number,omitempty"`
	EWayBillDocument string         `json:"eway_bill_document,omitempty"`
	CreatedAt        time.Time      `json:"created_at"`
	DeletedAt        gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

type Message struct {
	ID         uint           `gorm:"primaryKey" json:"id"`
	SenderID   uint           `gorm:"not null;index" json:"sender_id"`
	Sender     User           `gorm:"foreignKey:SenderID;" json:"sender,omitempty"`
	ReceiverID uint           `gorm:"not null;index" json:"receiver_id"`
	Receiver   User           `gorm:"foreignKey:ReceiverID;" json:"receiver,omitempty"`
	Content    string         `gorm:"not null" json:"content"`
	CreatedAt  time.Time      `gorm:"index" json:"created_at"`
	DeletedAt  gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

type Machinery struct {
	ID            uint           `gorm:"primaryKey" json:"id"`
	TenantID      uint           `gorm:"not null;index" json:"tenant_id"`
	Name          string         `gorm:"not null" json:"name"`
	Type          string         `json:"type"` // Added for Phase 4
	ModelNumber   string         `json:"model_number"`
	HourlyRate    float64        `json:"hourly_rate"`
	TotalHoursRun float64        `gorm:"default:0" json:"total_hours_run"`
	Status        string         `gorm:"default:'Active';index" json:"status"` // Active, Maintenance, Idle
	CreatedByID   *uint          `json:"created_by_id,omitempty"`
	UpdatedByID   *uint          `json:"updated_by_id,omitempty"`
	CreatedAt     time.Time      `json:"created_at"`
	DeletedAt     gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

type MachineryLog struct {
	ID          uint           `gorm:"primaryKey" json:"id"`
	TenantID    *uint          `gorm:"index" json:"tenant_id"`
	ProjectID   *uint          `gorm:"index" json:"project_id"`
	MachineryID uint           `gorm:"not null;index" json:"machinery_id"`
	Date        string         `gorm:"not null;index;default:''" json:"date"`
	UsageHours  float64        `gorm:"not null;default:0" json:"usage_hours"`
	FuelEntry   float64        `gorm:"default:0" json:"fuel_entry"`
	LoggedByID  uint           `gorm:"default:0" json:"logged_by_id"`
	Notes       string         `gorm:"default:''" json:"notes"`
	CreatedAt   time.Time      `json:"created_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

type SiteIssue struct {
	ID            uint      `gorm:"primaryKey" json:"id"`
	TenantID      uint      `gorm:"not null;index" json:"tenant_id"`
	ProjectID     uint      `gorm:"not null;index" json:"project_id"`
	Title         string    `gorm:"not null" json:"title"`
	Description   string    `json:"description"`
	Priority      string    `gorm:"default:'Medium'" json:"priority"` // Low, Medium, High, Critical
	Status        string    `gorm:"default:'Open'" json:"status"`     // Open, Closed
	ReportedBy    uint      `gorm:"not null" json:"reported_by"`
	ImageURLs     string    `json:"image_urls"`
	LowStockAlert uint      `json:"low_stock_alert"`
	Version       uint      `json:"version" gorm:"default:1"` // Optimistic locking
	CreatedAt     time.Time `json:"created_at"`
}

type LaborWorker struct {
	ID            uint           `gorm:"primaryKey" json:"id"`
	TenantID      uint           `gorm:"not null;index" json:"tenant_id"`
	Name          string         `gorm:"not null" json:"name"`
	SkillCategory string         `gorm:"not null;index" json:"skill_category"` // Mason, Helper, Operator, Carpenter
	DailyRate     float64        `gorm:"not null" json:"daily_rate"`
	CreatedByID   *uint          `json:"created_by_id,omitempty"`
	UpdatedByID   *uint          `json:"updated_by_id,omitempty"`
	CreatedAt     time.Time      `json:"created_at"`
	DeletedAt     gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

type AttendanceLog struct {
	ID            uint           `gorm:"primaryKey" json:"id"`
	LaborWorkerID uint           `gorm:"not null;uniqueIndex:idx_worker_date" json:"labor_worker_id"`
	Date          string         `gorm:"not null;uniqueIndex:idx_worker_date" json:"date"`
	Status        string         `gorm:"not null" json:"status"` // Present, Absent, Overtime
	OvertimeHours float64        `gorm:"default:0" json:"overtime_hours"`
	Latitude      float64        `gorm:"default:0" json:"latitude"`
	Longitude     float64        `gorm:"default:0" json:"longitude"`
	CreatedAt     time.Time      `json:"created_at"`
	DeletedAt     gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

type PayrollRecord struct {
	ID            uint           `gorm:"primaryKey" json:"id"`
	LaborWorkerID uint           `gorm:"not null;uniqueIndex:idx_worker_month" json:"labor_worker_id"`
	Month         string         `gorm:"not null;uniqueIndex:idx_worker_month" json:"month"` // YYYY-MM
	WagesEarned   float64        `gorm:"not null" json:"wages_earned"`
	Status        string         `gorm:"default:'Unpaid'" json:"status"` // Paid, Unpaid
	CreatedAt     time.Time      `json:"created_at"`
	DeletedAt     gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

// Expense tracks project/company expenses
type Expense struct {
	ID          uint           `gorm:"primaryKey" json:"id"`
	TenantID    uint           `gorm:"not null;index:idx_tenant_category" json:"tenant_id"`
	Tenant      Tenant         `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"-"`
	Category    string         `gorm:"not null;index:idx_tenant_category" json:"category"` // Fuel, Labour, Material, Equipment, Misc
	Amount      float64        `gorm:"not null" json:"amount"`
	Description string         `json:"description"`
	ExpenseDate string         `gorm:"not null;index" json:"expense_date"` // YYYY-MM-DD
	ProjectID   uint           `json:"project_id"`                         // Optional FK to project
	CreatedByID *uint          `json:"created_by_id,omitempty"`
	UpdatedByID *uint          `json:"updated_by_id,omitempty"`
	CreatedAt   time.Time      `json:"created_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
	UpdatedAt   time.Time      `json:"updated_at"`
}

// PurchaseOrder tracks material procurement
type PurchaseOrder struct {
	ID          uint           `gorm:"primaryKey" json:"id"`
	TenantID    uint           `gorm:"not null;index:idx_tenant_status" json:"tenant_id"`
	Tenant      Tenant         `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"-"`
	VendorName  string         `gorm:"not null" json:"vendor_name"`
	ItemName    string         `gorm:"not null" json:"item_name"`
	Quantity    float64        `gorm:"not null" json:"quantity"`
	Unit        string         `gorm:"not null" json:"unit"`
	UnitPrice   float64        `gorm:"not null" json:"unit_price"`
	TotalCost   float64        `gorm:"not null" json:"total_cost"`
	OrderDate   string         `gorm:"not null;index" json:"order_date"` // YYYY-MM-DD
	ExpectedBy  string         `json:"expected_by"`                      // YYYY-MM-DD
	ProjectID   uint           `json:"project_id"`
	VendorID    *uint          `json:"vendor_id,omitempty"`                                    // Optional link to Vendor user account
	Status      string         `gorm:"default:'Issued';index:idx_tenant_status" json:"status"` // Issued, Accepted, Rejected, Dispatched, Delivered, SupervisorVerified, ContractorConfirmed, Invoiced, Paid, Completed
	CreatedByID *uint          `json:"created_by_id,omitempty"`
	UpdatedByID *uint          `json:"updated_by_id,omitempty"`
	CreatedAt   time.Time      `json:"created_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
	UpdatedAt   time.Time      `json:"updated_at"`
}

// Notification tracks in-app alerts for users
type Notification struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	UserID    uint           `gorm:"not null;index" json:"user_id"`
	User      User           `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"-"`
	Title     string         `gorm:"not null" json:"title"`
	Message   string         `gorm:"not null" json:"message"`
	Type      string         `gorm:"default:'info';index" json:"type"` // info, warning, success, error, bid, tender, project
	Read      bool           `gorm:"default:false;index" json:"read"`
	RelatedID *uint          `json:"related_id,omitempty"` // Optional FK to related entity (project, tender, etc.)
	CreatedAt time.Time      `gorm:"index" json:"created_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

// ProjectTask tracks schedule tasks for Gantt chart
type ProjectTask struct {
	ID            uint           `gorm:"primaryKey" json:"id"`
	ProjectID     uint           `gorm:"not null;index:idx_task_project" json:"project_id"`
	Title         string         `gorm:"not null" json:"title"`
	Description   string         `json:"description"`
	Assignee      string         `json:"assignee"`
	StartDate     string         `gorm:"not null" json:"start_date"` // YYYY-MM-DD
	EndDate       string         `gorm:"not null" json:"end_date"`   // YYYY-MM-DD
	DurationDays  int            `gorm:"not null" json:"duration_days"`
	Progress      float64        `gorm:"default:0" json:"progress"` // 0-100
	Priority      string         `gorm:"default:'Medium';index" json:"priority"`
	Status        string         `gorm:"default:'Not Started';index" json:"status"` // Not Started, In Progress, Completed, On Hold
	DependencyIDs string         `gorm:"default:'[]'" json:"dependency_ids"`        // JSON array of task IDs
	ParentID      *uint          `json:"parent_id,omitempty"`                       // For subtask grouping
	CreatedAt     time.Time      `json:"created_at"`
	DeletedAt     gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
	UpdatedAt     time.Time      `json:"updated_at"`
}

// WorkOrder tracks site-level work tasks
type WorkOrder struct {
	ID          uint           `gorm:"primaryKey" json:"id"`
	TenantID    uint           `gorm:"not null;index:idx_tenant_status" json:"tenant_id"`
	Tenant      Tenant         `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"-"`
	Title       string         `gorm:"not null" json:"title"`
	Description string         `json:"description"`
	ProjectID   uint           `gorm:"index" json:"project_id"`
	AssignedTo  string         `json:"assigned_to"`                                          // Worker name or team
	DueDate     string         `json:"due_date"`                                             // YYYY-MM-DD
	Priority    string         `gorm:"default:'Medium';index" json:"priority"`               // Low, Medium, High, Critical
	Status      string         `gorm:"default:'Open';index:idx_tenant_status" json:"status"` // Open, InProgress, Completed, Cancelled
	CreatedByID *uint          `json:"created_by_id,omitempty"`
	UpdatedByID *uint          `json:"updated_by_id,omitempty"`
	CreatedAt   time.Time      `json:"created_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
	UpdatedAt   time.Time      `json:"updated_at"`
}

type GlobalAnnouncement struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	Title     string         `gorm:"not null" json:"title"`
	Message   string         `gorm:"not null" json:"message"`
	Type      string         `gorm:"default:'info';index" json:"type"` // info, warning, success
	IsActive  bool           `gorm:"default:true;index" json:"is_active"`
	CreatedAt time.Time      `json:"created_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

type SystemAuditLog struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Timestamp time.Time `gorm:"autoCreateTime" json:"timestamp"`
	Actor     string    `json:"actor"`
	Tenant    string    `json:"tenant"`
	Action    string    `json:"action"`
	IPAddress string    `json:"ip_address"`
}

type Inspection struct {
	ID          uint           `gorm:"primaryKey" json:"id"`
	TenantID    uint           `gorm:"not null;index" json:"tenant_id"`
	ProjectID   uint           `gorm:"not null;index" json:"project_id"`
	Title       string         `gorm:"not null" json:"title"`
	Description string         `json:"description"`
	InspectorID uint           `gorm:"index" json:"inspector_id"` // UserID
	Date        time.Time      `gorm:"index" json:"date"`
	Status      string         `gorm:"default:'Pending';index" json:"status"` // Pending, Passed, Failed
	Latitude    float64        `gorm:"default:0" json:"latitude"`
	Longitude   float64        `gorm:"default:0" json:"longitude"`
	CreatedAt   time.Time      `json:"created_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
	UpdatedAt   time.Time      `json:"updated_at"`
}

type Checklist struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	TenantID  uint           `gorm:"not null;index" json:"tenant_id"`
	ProjectID uint           `gorm:"not null;index" json:"project_id"`
	Title     string         `gorm:"not null" json:"title"`
	Category  string         `gorm:"not null;index" json:"category"` // Safety, Quality, etc.
	Completed bool           `gorm:"default:false;index" json:"completed"`
	CreatedAt time.Time      `json:"created_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
	UpdatedAt time.Time      `json:"updated_at"`
}

type Document struct {
	ID                 uint           `gorm:"primaryKey" json:"id"`
	TenantID           uint           `gorm:"not null;index" json:"tenant_id"`
	Name               string         `gorm:"not null" json:"name"`
	Category           string         `gorm:"default:'General';index" json:"category"` // Legal, Financial, Drawings, etc.
	FileType           string         `json:"file_type"`                               // PDF, PNG, etc.
	FileSize           int64          `json:"file_size"`
	FileURL            string         `gorm:"not null" json:"file_url"`
	UploadedBy         uint           `gorm:"index" json:"uploaded_by"`           // UserID
	SharedWithVendorID *uint          `gorm:"index" json:"shared_with_vendor_id"` // Nullable for general documents
	CreatedAt          time.Time      `json:"created_at"`
	DeletedAt          gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
	UpdatedAt          time.Time      `json:"updated_at"`
}
