package marketplace

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func ListVendorProducts(c *fiber.Ctx) error {
	vendorID := c.Locals("user_id").(uint)

	products := []models.VendorProduct{}
	if err := db.DB.Where("vendor_id = ?", vendorID).Find(&products).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch products", err)
	}

	return c.JSON(products)
}

type CreateProductRequest struct {
	Category    string  `json:"category" validate:"required"`
	Name        string  `json:"name" validate:"required"`
	Description string  `json:"description"`
	UnitPrice   float64 `json:"unit_price" validate:"required"`
	Unit        string  `json:"unit" validate:"required"`
}

func CreateVendorProduct(c *fiber.Ctx) error {
	vendorID := c.Locals("user_id").(uint)

	var req CreateProductRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request", err)
	}
	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	product := models.VendorProduct{
		VendorID:    vendorID,
		Category:    req.Category,
		Name:        req.Name,
		Description: req.Description,
		UnitPrice:   req.UnitPrice,
		Unit:        req.Unit,
	}

	if err := db.DB.Create(&product).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to create product", err)
	}

	return c.JSON(fiber.Map{"message": "Product created successfully", "product": product})
}

func GetVendorProfile(c *fiber.Ctx) error {
	vendorID := c.Locals("user_id").(uint)

	var user models.User
	if err := db.DB.Preload("Tenant").First(&user, vendorID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Vendor not found", err)
	}
	user.PasswordHash = ""

	return c.JSON(user)
}

type UpdateProfileRequest struct {
	GSTNumber     string `json:"gst_number"`
	ContactPerson string `json:"contact_person"`
	BankAccount   string `json:"bank_account"`
	IFSCCode      string `json:"ifsc_code"`
	BankDetails   string `json:"bank_details"`
}

func UpdateVendorProfile(c *fiber.Ctx) error {
	vendorID := c.Locals("user_id").(uint)

	var req UpdateProfileRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request", err)
	}

	updates := map[string]interface{}{}
	if req.GSTNumber != "" {
		updates["gst_number"] = req.GSTNumber
	}
	if req.ContactPerson != "" {
		updates["contact_person"] = req.ContactPerson
	}
	if req.BankAccount != "" {
		updates["bank_account"] = req.BankAccount
	}
	if req.IFSCCode != "" {
		updates["ifsc_code"] = req.IFSCCode
	}
	if req.BankDetails != "" {
		updates["bank_details"] = req.BankDetails
	}

	if err := db.DB.Model(&models.User{}).Where("id = ?", vendorID).Updates(updates).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update profile", err)
	}

	return c.JSON(fiber.Map{"message": "Profile updated successfully"})
}
