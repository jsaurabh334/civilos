package marketplace

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"
	"fmt"

	"github.com/gofiber/fiber/v2"
)

// GetVendorRatings returns all ratings for a vendor
func GetVendorRatings(c *fiber.Ctx) error {
	vendorID := c.Params("id")

	type Rating struct {
		ID           uint   `json:"id"`
		VendorID     uint   `json:"vendor_id"`
		ReviewerID   uint   `json:"reviewer_id"`
		ReviewerName string `json:"reviewer_name"`
		Rating       int    `json:"rating"`
		Comment      string `json:"comment"`
		CreatedAt    string `json:"created_at"`
	}

	ratings := []models.VendorRating{}
	if err := db.DB.Preload("Reviewer").Where("vendor_id = ?", vendorID).Order("created_at desc").Find(&ratings).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch ratings", err)
	}

	// Calculate average
	var total float64
	out := make([]map[string]interface{}, 0, len(ratings))
	for _, r := range ratings {
		total += float64(r.Rating)
		reviewerName := "Anonymous"
		if r.Reviewer != nil {
			reviewerName = r.Reviewer.Name
		}
		out = append(out, map[string]interface{}{
			"id":            r.ID,
			"vendor_id":     r.VendorID,
			"reviewer_name": reviewerName,
			"rating":        r.Rating,
			"comment":       r.Comment,
			"created_at":    r.CreatedAt,
		})
	}

	avg := 0.0
	if len(ratings) > 0 {
		avg = total / float64(len(ratings))
	}

	return c.JSON(fiber.Map{
		"ratings": out,
		"avg":     avg,
		"total":   len(ratings),
	})
}

// CreateVendorRating submits a review for a vendor
func CreateVendorRating(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	userID := c.Locals("user_id").(uint)
	vendorID := c.Params("id")

	type req struct {
		Rating  int    `json:"rating"`
		Comment string `json:"comment"`
	}
	var body req
	if err := c.BodyParser(&body); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}
	if body.Rating < 1 || body.Rating > 5 {
		return core.SendError(c, fiber.StatusBadRequest, "Rating must be between 1 and 5", nil)
	}

	// Check vendor exists
	var vendor models.Vendor
	if err := db.DB.Where("id = ?", vendorID).First(&vendor).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Vendor not found", err)
	}

	rating := models.VendorRating{
		VendorID:   vendor.ID,
		ReviewerID: userID,
		TenantID:   tenantID,
		Rating:     body.Rating,
		Comment:    core.Sanitize(body.Comment),
	}

	if err := db.DB.Create(&rating).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to save rating", err)
	}

	// Record basic audit log
	db.LogAudit(
		fmt.Sprintf("User:%d", userID),
		fmt.Sprintf("Tenant:%d", tenantID),
		fmt.Sprintf("vendor_review (Vendor:%d)", vendor.ID),
		c.IP(),
	)

	return c.Status(fiber.StatusCreated).JSON(rating)
}
