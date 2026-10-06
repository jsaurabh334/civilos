package inventory

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"testing"

	"civilos/backend/internal/db"
	"civilos/backend/internal/middleware"
	"civilos/backend/internal/models"
	"civilos/backend/internal/testutil"

	"github.com/gofiber/fiber/v2"
)

func setupInventoryApp(t *testing.T) (*fiber.App, models.Tenant, models.User, string) {
	t.Helper()
	testutil.SetupTestDB(t)

	tenant := testutil.CreateTestTenant(t)
	user := testutil.CreateTestUser(t, tenant.ID, "Contractor")
	token := testutil.GenerateTestToken(user.ID, user.Email, user.Role, &tenant.ID)

	app := fiber.New()

	protected := app.Group("", middleware.AuthRequired, middleware.TenantScope)
	protected.Get("/inventory", ListInventory)
	protected.Post("/inventory", CreateInventoryItem)
	protected.Post("/inventory/transactions", RecordTransaction)

	return app, tenant, user, token
}

func TestListInventory_TenantScoped(t *testing.T) {
	app, tenant, _, token := setupInventoryApp(t)

	item1 := models.InventoryItem{
		TenantID: tenant.ID,
		ItemName: "Cement",
		SKU:      "CEM-001",
		Category: "Material",
		Unit:     "Bags",
		Quantity: 100,
	}
	db.DB.Create(&item1)

	item2 := models.InventoryItem{
		TenantID: tenant.ID,
		ItemName: "Steel",
		SKU:      "STL-001",
		Category: "Material",
		Unit:     "Tons",
		Quantity: 10,
	}
	db.DB.Create(&item2)

	otherTenant := testutil.CreateTestTenant(t)
	otherItem := models.InventoryItem{
		TenantID: otherTenant.ID,
		ItemName: "Other Tenant Item",
		SKU:      "OTH-001",
		Category: "Material",
		Unit:     "Units",
		Quantity: 5,
	}
	db.DB.Create(&otherItem)

	req, _ := http.NewRequest("GET", "/inventory", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}

	var items []models.InventoryItem
	data, _ := io.ReadAll(resp.Body)
	json.Unmarshal(data, &items)

	if len(items) != 2 {
		t.Fatalf("expected 2 items for tenant, got %d", len(items))
	}
	for _, it := range items {
		if it.ItemName == "Other Tenant Item" {
			t.Fatal("should not return items from other tenant")
		}
	}
}

func TestCreateInventoryItem_ValidData(t *testing.T) {
	app, _, _, token := setupInventoryApp(t)

	body, _ := json.Marshal(CreateInventoryItemRequest{
		ItemName:    "River Sand",
		Category:    "Material",
		Unit:        "Cum",
		Quantity:    50,
		SafetyStock: 20,
	})
	req, _ := http.NewRequest("POST", "/inventory", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("expected 201, got %d", resp.StatusCode)
	}

	var item models.InventoryItem
	data, _ := io.ReadAll(resp.Body)
	json.Unmarshal(data, &item)

	if item.ItemName != "River Sand" {
		t.Fatalf("expected item name, got %s", item.ItemName)
	}
	if item.Quantity != 50 {
		t.Fatalf("expected quantity 50, got %f", item.Quantity)
	}
}

func TestCreateInventoryItem_InvalidData(t *testing.T) {
	app, _, _, token := setupInventoryApp(t)

	body, _ := json.Marshal(CreateInventoryItemRequest{
		ItemName: "",
		Unit:     "",
	})
	req, _ := http.NewRequest("POST", "/inventory", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", resp.StatusCode)
	}
}

func TestRecordTransaction_ReducesStock(t *testing.T) {
	app, tenant, _, token := setupInventoryApp(t)

	item := models.InventoryItem{
		TenantID: tenant.ID,
		ItemName: "Bricks",
		SKU:      "BRK-001",
		Category: "Material",
		Unit:     "Nos",
		Quantity: 1000,
	}
	db.DB.Create(&item)

	body, _ := json.Marshal(RecordTransactionRequest{
		InventoryItemID: item.ID,
		Type:            "OUT",
		Quantity:        200,
		TransactionDate: "2026-07-01",
	})
	req, _ := http.NewRequest("POST", "/inventory/transactions", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("expected 201, got %d", resp.StatusCode)
	}

	var updated models.InventoryItem
	db.DB.First(&updated, item.ID)
	if updated.Quantity != 800 {
		t.Fatalf("expected quantity 800 after OUT transaction, got %f", updated.Quantity)
	}

	var txCount int64
	db.DB.Model(&models.MaterialTransaction{}).Where("inventory_item_id = ?", item.ID).Count(&txCount)
	if txCount != 1 {
		t.Fatalf("expected 1 transaction, got %d", txCount)
	}
}

func TestRecordTransaction_IncreasesStock(t *testing.T) {
	app, tenant, _, token := setupInventoryApp(t)

	item := models.InventoryItem{
		TenantID: tenant.ID,
		ItemName: "Fuel Diesel",
		SKU:      "DSL-001",
		Category: "Fuel",
		Unit:     "Liters",
		Quantity: 500,
	}
	db.DB.Create(&item)

	body, _ := json.Marshal(RecordTransactionRequest{
		InventoryItemID: item.ID,
		Type:            "IN",
		Quantity:        100,
		TransactionDate: "2026-07-01",
	})
	req, _ := http.NewRequest("POST", "/inventory/transactions", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("expected 201, got %d", resp.StatusCode)
	}

	var updated models.InventoryItem
	db.DB.First(&updated, item.ID)
	if updated.Quantity != 600 {
		t.Fatalf("expected quantity 600 after IN transaction, got %f", updated.Quantity)
	}
}

func TestRecordTransaction_InsufficientStock(t *testing.T) {
	app, tenant, _, token := setupInventoryApp(t)

	item := models.InventoryItem{
		TenantID: tenant.ID,
		ItemName: "Nails",
		SKU:      "NL-001",
		Category: "Material",
		Unit:     "Kg",
		Quantity: 10,
	}
	db.DB.Create(&item)

	body, _ := json.Marshal(RecordTransactionRequest{
		InventoryItemID: item.ID,
		Type:            "OUT",
		Quantity:        100,
		TransactionDate: "2026-07-01",
	})
	req, _ := http.NewRequest("POST", "/inventory/transactions", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusBadRequest {
		t.Fatalf("expected 400 for insufficient stock, got %d", resp.StatusCode)
	}

	var updated models.InventoryItem
	db.DB.First(&updated, item.ID)
	if updated.Quantity != 10 {
		t.Fatalf("quantity should remain unchanged; got %f", updated.Quantity)
	}
}
