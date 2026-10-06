package models

import (
	"time"

	"gorm.io/gorm"
)

// Main Tender Table
type Tender struct {
	ID           uint   `gorm:"primaryKey" json:"id"`
	TenantID     uint   `gorm:"not null;index" json:"tenant_id"`
	Tenant       Tenant `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"-"`
	TenderNo     string `gorm:"index" json:"tender_no"`
	TenderName   string `gorm:"not null" json:"tender_name"`
	TenderType   string `json:"tender_type"` // Government, Private
	Department   string `json:"department"`
	Organization string `json:"organization"`
	Category     string `json:"category"`
	SubCategory  string `json:"sub_category"`
	Status       string `gorm:"default:'Draft';index" json:"status"` // Draft, Published, Under Review, Estimation Running, Ready To Submit, Submitted, Technical Qualified, Financial Qualified, Awarded, Lost, Cancelled, Work Started, Completed

	// Relationships
	Client           TenderClient      `gorm:"foreignKey:TenderID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"client"`
	Details          TenderDetail      `gorm:"foreignKey:TenderID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"details"`
	Location         TenderLocation    `gorm:"foreignKey:TenderID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"location"`
	Scope            TenderScope       `gorm:"foreignKey:TenderID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"scope"`
	WorkDetails      TenderWorkDetail  `gorm:"foreignKey:TenderID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"work_details"`
	Eligibility      TenderEligibility `gorm:"foreignKey:TenderID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"eligibility"`
	ImportantDates   TenderDates       `gorm:"foreignKey:TenderID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"important_dates"`
	InternalTracking TenderTracking    `gorm:"foreignKey:TenderID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"internal_tracking"`
	BOQItems         []TenderBOQ       `gorm:"foreignKey:TenderID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"boq_items"`
	Documents        []TenderDocument  `gorm:"foreignKey:TenderID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"documents"`

	CreatedByID uint           `json:"created_by_id"`
	CreatedAt   time.Time      `json:"created_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
	UpdatedAt   time.Time      `json:"updated_at"`
}

type TenderClient struct {
	ID            uint   `gorm:"primaryKey" json:"id"`
	TenderID      uint   `gorm:"uniqueIndex;not null" json:"tender_id"`
	ClientName    string `json:"client_name"`
	Department    string `json:"department"`
	ContactPerson string `json:"contact_person"`
	Designation   string `json:"designation"`
	Email         string `json:"email"`
	Mobile        string `json:"mobile"`
	OfficeAddress string `json:"office_address"`
	GSTNo         string `json:"gst_no"`
	PAN           string `json:"pan"`
}

type TenderDetail struct {
	ID                  uint    `gorm:"primaryKey" json:"id"`
	TenderID            uint    `gorm:"uniqueIndex;not null" json:"tender_id"`
	EstimatedCost       float64 `json:"estimated_cost"`
	TenderFee           float64 `json:"tender_fee"`
	EMDAmount           float64 `json:"emd_amount"`
	SecurityDepositPct  float64 `json:"security_deposit_pct"`
	PerformanceBGPct    float64 `json:"performance_bg_pct"`
	RetentionPct        float64 `json:"retention_pct"`
	DefectLiabilityDays int     `json:"defect_liability_days"`
	BidValidityDays     int     `json:"bid_validity_days"`
	CompletionTimeDays  int     `json:"completion_time_days"`
}

type TenderLocation struct {
	ID        uint    `gorm:"primaryKey" json:"id"`
	TenderID  uint    `gorm:"uniqueIndex;not null" json:"tender_id"`
	Country   string  `json:"country"`
	State     string  `json:"state"`
	District  string  `json:"district"`
	City      string  `json:"city"`
	Address   string  `json:"address"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Pincode   string  `json:"pincode"`
}

type TenderScope struct {
	ID          uint   `gorm:"primaryKey" json:"id"`
	TenderID    uint   `gorm:"uniqueIndex;not null" json:"tender_id"`
	ProjectType string `json:"project_type"` // Building, Road, Bridge, Water Supply, PHE, Electrical, Industrial, Residential, Commercial, Hospital, School, Pipeline, Railway, Airport, Metro, Others
}

type TenderWorkDetail struct {
	ID                uint    `gorm:"primaryKey" json:"id"`
	TenderID          uint    `gorm:"uniqueIndex;not null" json:"tender_id"`
	ProjectDesc       string  `json:"project_description"`
	TotalArea         float64 `json:"total_area"`
	BuiltUpArea       float64 `json:"built_up_area"`
	Length            float64 `json:"length"`
	Width             float64 `json:"width"`
	Height            float64 `json:"height"`
	RoadLength        float64 `json:"road_length"`
	NoOfFloors        int     `json:"no_of_floors"`
	EstimatedLabour   float64 `json:"estimated_labour"`
	EstimatedMaterial float64 `json:"estimated_material"`
}

type TenderEligibility struct {
	ID                 uint    `gorm:"primaryKey" json:"id"`
	TenderID           uint    `gorm:"uniqueIndex;not null" json:"tender_id"`
	MinimumTurnover    float64 `json:"minimum_turnover"`
	ExperienceRequired string  `json:"experience_required"`
	SimilarWorks       string  `json:"similar_works"`
	Class              string  `json:"class"`
	RegistrationReq    string  `json:"registration_required"`
	GSTMandatory       bool    `json:"gst_mandatory"`
	PFMandatory        bool    `json:"pf_mandatory"`
	ESIMandatory       bool    `json:"esi_mandatory"`
	ISOMandatory       bool    `json:"iso_mandatory"`
	MSMEAllowed        bool    `json:"msme_allowed"`
	StartupAllowed     bool    `json:"startup_allowed"`
	JVAllowed          bool    `json:"jv_allowed"`
	ConsortiumAllowed  bool    `json:"consortium_allowed"`
}

type TenderDates struct {
	ID                 uint       `gorm:"primaryKey" json:"id"`
	TenderID           uint       `gorm:"uniqueIndex;not null" json:"tender_id"`
	PublishDate        *time.Time `json:"publish_date"`
	DownloadStartDate  *time.Time `json:"download_start_date"`
	DownloadEndDate    *time.Time `json:"download_end_date"`
	PreBidMeetingDate  *time.Time `json:"pre_bid_meeting_date"`
	QueryLastDate      *time.Time `json:"query_last_date"`
	SubmissionLastDate *time.Time `json:"submission_last_date"`
	TechnicalOpening   *time.Time `json:"technical_opening_date"`
	FinancialOpening   *time.Time `json:"financial_opening_date"`
}

type TenderTracking struct {
	ID                   uint    `gorm:"primaryKey" json:"id"`
	TenderID             uint    `gorm:"uniqueIndex;not null" json:"tender_id"`
	TenderOwner          string  `json:"tender_owner"`
	Estimator            string  `json:"estimator"`
	Reviewer             string  `json:"reviewer"`
	ApprovalBy           string  `json:"approval_by"`
	Priority             string  `json:"priority"` // High, Medium, Low
	ProbabilityOfWinning float64 `json:"probability_of_winning"`
	Remarks              string  `json:"remarks"`
}

type TenderBOQ struct {
	ID           uint    `gorm:"primaryKey" json:"id"`
	TenderID     uint    `gorm:"not null;index" json:"tender_id"`
	ItemNo       string  `json:"item_no"`
	Description  string  `json:"description"`
	Unit         string  `json:"unit"`
	Quantity     float64 `json:"quantity"`
	Rate         float64 `json:"rate"`
	Amount       float64 `json:"amount"`
	GSTPct       float64 `json:"gst_pct"`
	MaterialCost float64 `json:"material_cost"`
	LabourCost   float64 `json:"labour_cost"`
	MachineCost  float64 `json:"machine_cost"`
	OverheadCost float64 `json:"overhead_cost"`
	ProfitPct    float64 `json:"profit_pct"`
	Remarks      string  `json:"remarks"`
}

type TenderDocument struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	TenderID     uint      `gorm:"not null;index" json:"tender_id"`
	DocumentType string    `json:"document_type"` // NIT, BOQ, Specs, Drawings, Corrigendum, PreBid, Agreement, Photos, Maps
	FileURL      string    `json:"file_url"`
	FileName     string    `json:"file_name"`
	UploadedAt   time.Time `json:"uploaded_at"`
}
