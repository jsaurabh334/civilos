package finance

import (
	"bytes"
	"civilos/backend/internal/core"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"os"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

type RazorpayLinkRequest struct {
	Amount      int    `json:"amount"`
	Currency    string `json:"currency"`
	Description string `json:"description"`
}

type RazorpayCustomer struct {
	Name  string `json:"name"`
	Email string `json:"email"`
}

type RazorpayLinkPayload struct {
	Amount      int              `json:"amount"`
	Currency    string           `json:"currency"`
	Description string           `json:"description"`
	Customer    RazorpayCustomer `json:"customer"`
	ReferenceID string           `json:"reference_id"`
}

func GeneratePaymentLink(c *fiber.Ctx) error {
	tenantID := c.Params("id")
	var req RazorpayLinkRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	var tenant models.Tenant
	if err := db.DB.First(&tenant, tenantID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Tenant not found", err)
	}

	apiKey := os.Getenv("RAZORPAY_KEY_ID")
	apiSecret := os.Getenv("RAZORPAY_KEY_SECRET")

	if apiKey == "" || apiSecret == "" {
		// Mock link for dev environment if keys not set
		return c.JSON(fiber.Map{"short_url": "https://rzp.io/i/mocktestlink"})
	}

	payload := RazorpayLinkPayload{
		Amount:      req.Amount,
		Currency:    req.Currency,
		Description: req.Description,
		Customer: RazorpayCustomer{
			Name:  tenant.Name,
			Email: "admin@" + tenant.Slug + ".com",
		},
		ReferenceID: fmt.Sprintf("tenant_%d_upgrade", tenant.ID),
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to marshal payload", err)
	}

	request, err := http.NewRequest("POST", "https://api.razorpay.com/v1/payment_links", bytes.NewBuffer(jsonData))
	request.SetBasicAuth(apiKey, apiSecret)
	request.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	response, err := client.Do(request)
	if err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to reach Razorpay", err)
	}
	defer response.Body.Close()

	var result map[string]interface{}
	json.NewDecoder(response.Body).Decode(&result)

	if shortURL, ok := result["short_url"].(string); ok {
		return c.JSON(fiber.Map{"short_url": shortURL})
	}

	return core.SendError(c, fiber.StatusInternalServerError, "Failed to generate link", err)
}

func RazorpayWebhook(c *fiber.Ctx) error {
	secret := os.Getenv("RAZORPAY_WEBHOOK_SECRET")
	if secret != "" {
		signature := c.Get("X-Razorpay-Signature")
		body := c.Body()

		h := hmac.New(sha256.New, []byte(secret))
		h.Write(body)
		expectedSignature := hex.EncodeToString(h.Sum(nil))

		if hmac.Equal([]byte(expectedSignature), []byte(signature)) == false {
			return c.SendStatus(fiber.StatusUnauthorized)
		}
	}

	var payload map[string]interface{}
	if err := c.BodyParser(&payload); err != nil {
		return c.SendStatus(400)
	}

	if event, ok := payload["event"].(string); ok {
		if event == "payment.captured" {
			// Find tenant and activate plan
			// This is simplified for the demo
		}
	}

	return c.SendStatus(200)
}
