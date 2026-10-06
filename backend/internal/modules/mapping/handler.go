package mapping

import (
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func GetMapData(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	projects := make([]models.Project, 0)
	db.DB.Where("tenant_id = ?", tenantID).
		Select("id, name, location, latitude, longitude, status, budget").
		Find(&projects)

	// Build map markers — only projects with coordinates
	markers := make([]fiber.Map, 0)
	for _, p := range projects {
		if p.Latitude != 0 || p.Longitude != 0 {
			markers = append(markers, fiber.Map{
				"id":       p.ID,
				"name":     p.Name,
				"location": p.Location,
				"lat":      p.Latitude,
				"lng":      p.Longitude,
				"status":   p.Status,
				"budget":   p.Budget,
			})
		}
	}

	return c.JSON(fiber.Map{
		"markers": markers,
	})
}
