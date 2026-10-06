package inventory

import (
	"time"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

// GetPriceHistory returns 12-month average unit price history for a material
// based on Purchase Order data for that item name/category.
func GetPriceHistory(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	materialName := c.Query("material", "")

	type MonthPrice struct {
		Month string  `json:"month"`
		Price float64 `json:"price"`
		Unit  string  `json:"unit"`
	}

	// Find inventory item for unit label
	var item models.InventoryItem
	q := db.DB.Where("tenant_id = ?", tenantID)
	if materialName != "" {
		q = q.Where("item_name LIKE ?", "%"+materialName+"%")
	}
	_ = q.First(&item) // ignore not-found — use empty fallback

	// Build 12-month history from PurchaseOrders
	history := make([]MonthPrice, 0, 12)
	now := time.Now()
	for i := 11; i >= 0; i-- {
		month := time.Date(now.Year(), now.Month()-time.Month(i), 1, 0, 0, 0, 0, time.UTC)
		nextMonth := month.AddDate(0, 1, 0)

		type Result struct {
			AvgPrice float64
		}
		var res Result
		poQuery := db.DB.Model(&models.PurchaseOrder{}).
			Select("AVG(unit_price) as avg_price").
			Where("tenant_id = ? AND order_date >= ? AND order_date < ?",
				tenantID,
				month.Format("2006-01-02"),
				nextMonth.Format("2006-01-02"),
			)
		if materialName != "" {
			poQuery = poQuery.Where("item_name LIKE ?", "%"+materialName+"%")
		}
		poQuery.Scan(&res)

		history = append(history, MonthPrice{
			Month: month.Format("Jan 06"),
			Price: res.AvgPrice,
			Unit:  item.Unit,
		})
	}

	return c.JSON(fiber.Map{
		"history": history,
		"item": fiber.Map{
			"id":        item.ID,
			"item_name": item.ItemName,
			"unit":      item.Unit,
		},
	})
}
