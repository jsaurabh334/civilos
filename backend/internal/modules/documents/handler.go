package documents

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

// GetDocuments returns all documents for the tenant
func GetDocuments(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	docs := make([]models.Document, 0)
	if err := db.DB.Where("tenant_id = ?", tenantID).Order("created_at desc").Find(&docs).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to fetch documents"})
	}

	return c.JSON(docs)
}

// UploadDocument handles file uploads
func UploadDocument(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	userID := c.Locals("user_id").(uint)

	// Get category if provided
	category := c.FormValue("category", "General")

	// Get first file from form field "file"
	file, err := c.FormFile("file")
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "No file uploaded"})
	}

	// Create uploads directory if it doesn't exist
	uploadsDir := "./uploads/documents"
	if err := os.MkdirAll(uploadsDir, os.ModePerm); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to create upload directory"})
	}

	// Generate a unique filename
	fileName := fmt.Sprintf("%d_%s", time.Now().UnixNano(), file.Filename)
	savePath := filepath.Join(uploadsDir, fileName)

	// Save the file
	if err := c.SaveFile(file, savePath); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to save file"})
	}

	// In a real app, fileUrl would point to S3 or a public URL. Here we use the local API path
	fileUrl := fmt.Sprintf("/uploads/documents/%s", fileName)

	// Get optional vendor ID
	var vendorIDPtr *uint
	vendorIDStr := c.FormValue("shared_with_vendor_id", "")
	if vendorIDStr != "" {
		var vid uint
		if _, err := fmt.Sscanf(vendorIDStr, "%d", &vid); err == nil {
			vendorIDPtr = &vid
		}
	}

	// Create Document record
	doc := models.Document{
		TenantID:           tenantID,
		Name:               file.Filename,
		Category:           category,
		FileType:           filepath.Ext(file.Filename),
		FileSize:           file.Size,
		FileURL:            fileUrl,
		UploadedBy:         userID,
		SharedWithVendorID: vendorIDPtr,
	}

	if err := db.DB.Create(&doc).Error; err != nil {
		// Clean up file if db save fails
		os.Remove(savePath)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to save document metadata"})
	}

	return c.Status(fiber.StatusCreated).JSON(doc)
}

// DeleteDocument removes a document
func DeleteDocument(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	id := c.Params("id")

	var doc models.Document
	if err := db.DB.Where("id = ? AND tenant_id = ?", id, tenantID).First(&doc).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Document not found"})
	}

	// Delete from DB
	if err := db.DB.Delete(&doc).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to delete document"})
	}

	return c.JSON(fiber.Map{"message": "Document deleted successfully"})
}
