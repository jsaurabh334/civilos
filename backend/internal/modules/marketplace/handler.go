package marketplace

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func ListMarketplaceListings(c *fiber.Ctx) error {
	listings := []models.MarketplaceListing{}
	category := c.Query("category")

	limit := c.QueryInt("limit", 50)
	page := c.QueryInt("page", 1)
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	if page <= 0 {
		page = 1
	}
	offset := (page - 1) * limit

	query := db.DB.Preload("Tenant").Where("status = ?", "Open").Offset(offset).Limit(limit)
	if category != "" {
		query = query.Where("category = ?", category)
	}

	if err := query.Find(&listings).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch marketplace listings", err)
	}

	return c.JSON(listings)
}

type CreateListingRequest struct {
	Category    string  `json:"category"`
	Title       string  `json:"title"`
	Description string  `json:"description"`
	Quantity    float64 `json:"quantity"`
	Price       float64 `json:"price"`
	Unit        string  `json:"unit"`
	ContactInfo string  `json:"contact_info"`
}

func CreateMarketplaceListing(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	var req CreateListingRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Category = core.Sanitize(req.Category)
	req.Title = core.Sanitize(req.Title)
	req.Description = core.Sanitize(req.Description)
	req.Unit = core.Sanitize(req.Unit)
	req.ContactInfo = core.Sanitize(req.ContactInfo)

	validCategories := map[string]bool{
		"BuyMaterial": true, "RentMachinery": true, "HireLabour": true, "HireEngineer": true,
		"SellScrap": true, "SellExcessCement": true, "SellSteel": true, "RentShuttering": true, "RentScaffolding": true,
	}
	if !validCategories[req.Category] {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid marketplace category", nil)
	}

	if req.Title == "" {
		return core.SendError(c, fiber.StatusBadRequest, "Title is required", nil)
	}

	// Validate against negative/zero quantities and prices
	if req.Quantity <= 0 || req.Price <= 0 {
		return core.SendError(c, fiber.StatusBadRequest, "Quantity and Price must be greater than zero", nil)
	}

	listing := models.MarketplaceListing{
		TenantID:    tenantID,
		Category:    req.Category,
		Title:       req.Title,
		Description: req.Description,
		Quantity:    req.Quantity,
		Price:       req.Price,
		Unit:        req.Unit,
		ContactInfo: req.ContactInfo,
		Status:      "Open",
	}

	if err := db.DB.Create(&listing).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to publish listing", err)
	}

	// Preload Tenant for response
	db.DB.Preload("Tenant").First(&listing, listing.ID)

	return c.Status(fiber.StatusCreated).JSON(listing)
}

type UpdateListingRequest struct {
	Title       string  `json:"title"`
	Description string  `json:"description"`
	Quantity    float64 `json:"quantity"`
	Price       float64 `json:"price"`
	Unit        string  `json:"unit"`
	ContactInfo string  `json:"contact_info"`
	Status      string  `json:"status"` // Open, Closed
}

func UpdateMarketplaceListing(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	listingID := c.Params("id")

	var listing models.MarketplaceListing
	if err := db.DB.First(&listing, listingID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Listing not found", err)
	}
	if listing.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}

	var req UpdateListingRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Title = core.Sanitize(req.Title)
	req.Description = core.Sanitize(req.Description)
	req.Unit = core.Sanitize(req.Unit)
	req.ContactInfo = core.Sanitize(req.ContactInfo)
	req.Status = core.Sanitize(req.Status)

	if req.Title != "" {
		listing.Title = req.Title
	}
	if req.Description != "" {
		listing.Description = req.Description
	}
	if req.Quantity > 0 {
		listing.Quantity = req.Quantity
	}
	if req.Price > 0 {
		listing.Price = req.Price
	}
	if req.Unit != "" {
		listing.Unit = req.Unit
	}
	if req.ContactInfo != "" {
		listing.ContactInfo = req.ContactInfo
	}
	if req.Status == "Open" || req.Status == "Closed" {
		listing.Status = req.Status
	}

	if err := db.DB.Save(&listing).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update listing", err)
	}
	db.DB.Preload("Tenant").First(&listing, listing.ID)
	return c.JSON(listing)
}

func DeleteMarketplaceListing(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	listingID := c.Params("id")

	var listing models.MarketplaceListing
	if err := db.DB.First(&listing, listingID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Listing not found", err)
	}
	if listing.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}

	if err := db.DB.Delete(&listing).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to delete listing", err)
	}
	return c.JSON(fiber.Map{"message": "Listing deleted"})
}
