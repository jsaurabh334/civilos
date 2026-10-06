package marketplace

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func ListB2BPartners(c *fiber.Ctx) error {
	partners := []models.B2BPartner{}
	partnerType := c.Query("type")
	offset, limit := core.GetPagination(c)

	query := db.DB
	if partnerType != "" {
		query = query.Where("type = ?", partnerType)
	}

	if err := query.Offset(offset).Limit(limit).Find(&partners).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch partners", err)
	}

	return c.JSON(partners)
}

type CreatePartnerRequest struct {
	Name        string `json:"name"`
	Type        string `json:"type"`
	Services    string `json:"services"`
	Location    string `json:"location"`
	ContactInfo string `json:"contact_info"`
}

func CreateB2BPartner(c *fiber.Ctx) error {
	var req CreatePartnerRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Name = core.Sanitize(req.Name)
	req.Type = core.Sanitize(req.Type)
	req.Services = core.Sanitize(req.Services)
	req.Location = core.Sanitize(req.Location)
	req.ContactInfo = core.Sanitize(req.ContactInfo)

	if req.Name == "" || (req.Type != "Vendor" && req.Type != "Transporter") {
		return core.SendError(c, fiber.StatusBadRequest, "Name and valid Type (Vendor/Transporter) are required", nil)
	}

	partner := models.B2BPartner{
		Name:        req.Name,
		Type:        req.Type,
		Services:    req.Services,
		Location:    req.Location,
		ContactInfo: req.ContactInfo,
		Rating:      5.0, // Default rating
	}

	if err := db.DB.Create(&partner).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to create partner entry", err)
	}

	return c.Status(fiber.StatusCreated).JSON(partner)
}

func UpdateB2BPartner(c *fiber.Ctx) error {
	partnerID := c.Params("id")

	var partner models.B2BPartner
	if err := db.DB.First(&partner, partnerID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Partner not found", err)
	}

	var req CreatePartnerRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	req.Name = core.Sanitize(req.Name)
	req.Type = core.Sanitize(req.Type)
	req.Services = core.Sanitize(req.Services)
	req.Location = core.Sanitize(req.Location)
	req.ContactInfo = core.Sanitize(req.ContactInfo)

	if req.Name != "" {
		partner.Name = req.Name
	}
	if req.Type == "Vendor" || req.Type == "Transporter" {
		partner.Type = req.Type
	}
	if req.Services != "" {
		partner.Services = req.Services
	}
	if req.Location != "" {
		partner.Location = req.Location
	}
	if req.ContactInfo != "" {
		partner.ContactInfo = req.ContactInfo
	}

	if err := db.DB.Save(&partner).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update partner", err)
	}
	return c.JSON(partner)
}

func DeleteB2BPartner(c *fiber.Ctx) error {
	partnerID := c.Params("id")

	var partner models.B2BPartner
	if err := db.DB.First(&partner, partnerID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Partner not found", err)
	}

	if err := db.DB.Delete(&partner).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to delete partner", err)
	}
	return c.JSON(fiber.Map{"message": "Partner deleted successfully"})
}
