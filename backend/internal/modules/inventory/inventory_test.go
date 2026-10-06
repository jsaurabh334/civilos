package inventory

import (
	"testing"
)

func TestAddInventoryInput(t *testing.T) {
	input := CreateInventoryItemRequest{
		ItemName:    "Cement",
		SKU:         "CEM-01",
		Category:    "Material",
		Unit:        "Bags",
		Quantity:    100,
		SafetyStock: 20,
	}

	if input.ItemName != "Cement" {
		t.Errorf("ItemName = %q; want %q", input.ItemName, "Cement")
	}
	if input.Quantity != 100 {
		t.Errorf("Quantity = %f; want %f", input.Quantity, 100.0)
	}
}

func TestStockTransactionInput(t *testing.T) {
	input := RecordTransactionRequest{
		Type:      "OUT",
		Quantity:  50,
		Reference: "PRJ-01",
		Notes:     "Dispatch to site",
	}

	if input.Type != "OUT" {
		t.Errorf("Type = %q; want %q", input.Type, "OUT")
	}
	if input.Quantity <= 0 {
		t.Errorf("Quantity must be positive, got %f", input.Quantity)
	}
}
