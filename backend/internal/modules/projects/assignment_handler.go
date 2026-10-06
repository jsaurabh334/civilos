package projects

import (
	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"
	"math"

	"github.com/gofiber/fiber/v2"
)

type AssignSupervisorRequest struct {
	UserID    uint    `json:"user_id" validate:"required"`
	StartDate *string `json:"start_date" validate:"omitempty"`
	EndDate   *string `json:"end_date" validate:"omitempty"`
}

func AssignSupervisor(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	projectID := c.Params("id")

	var req AssignSupervisorRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	// Verify project belongs to tenant
	var project models.Project
	if err := db.DB.Where("id = ? AND tenant_id = ?", projectID, tenantID).First(&project).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Project not found", err)
	}

	// Verify the user being assigned is a supervisor belonging to the SAME tenant
	var supervisor models.User
	if err := db.DB.Where("id = ? AND tenant_id = ? AND role = ?", req.UserID, tenantID, "Supervisor").First(&supervisor).Error; err != nil {
		return core.SendError(c, fiber.StatusForbidden, "User is not a supervisor or does not belong to your tenant", err)
	}

	// Validate dates if provided
	if req.StartDate != nil && !core.IsValidDate(*req.StartDate) {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid start_date format. Expected YYYY-MM-DD", nil)
	}
	if req.EndDate != nil && !core.IsValidDate(*req.EndDate) {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid end_date format. Expected YYYY-MM-DD", nil)
	}

	// Prevent overlapping/duplicate assignments
	var existing models.ProjectAssignment
	if err := db.DB.Where("project_id = ? AND user_id = ?", project.ID, req.UserID).First(&existing).Error; err == nil {
		return core.SendError(c, fiber.StatusConflict, "Supervisor is already assigned to this project", nil)
	}

	// Create assignment
	assignment := models.ProjectAssignment{
		ProjectID: project.ID,
		UserID:    req.UserID,
		StartDate: req.StartDate,
		EndDate:   req.EndDate,
	}
	if err := db.DB.Create(&assignment).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to assign supervisor", err)
	}

	return c.JSON(assignment)
}

func RemoveSupervisor(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	projectID := c.Params("id")
	userID := c.Params("assignment_id")

	// Verify project belongs to tenant
	var project models.Project
	if err := db.DB.Where("id = ? AND tenant_id = ?", projectID, tenantID).First(&project).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Project not found", err)
	}

	// Soft delete assignment
	if err := db.DB.Where("project_id = ? AND user_id = ?", project.ID, userID).Delete(&models.ProjectAssignment{}).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to remove assignment", err)
	}

	return c.SendStatus(fiber.StatusNoContent)
}

type SupervisorLocationResponse struct {
	UserID             uint    `json:"user_id"`
	Name               string  `json:"name"`
	Email              string  `json:"email"`
	LastLatitude       float64 `json:"last_latitude"`
	LastLongitude      float64 `json:"last_longitude"`
	LastLocationUpdate string  `json:"last_location_update"`
	DistanceFromSiteKm float64 `json:"distance_from_site_km"`
}

// Haversine calculates distance in kilometers
func haversine(lat1, lon1, lat2, lon2 float64) float64 {
	const R = 6371 // Earth radius in km
	dLat := (lat2 - lat1) * math.Pi / 180.0
	dLon := (lon2 - lon1) * math.Pi / 180.0

	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180.0)*math.Cos(lat2*math.Pi/180.0)*
			math.Sin(dLon/2)*math.Sin(dLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return R * c
}

func GetSupervisorsLocation(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	projectID := c.Params("id")

	var project models.Project
	if err := db.DB.Where("id = ? AND tenant_id = ?", projectID, tenantID).First(&project).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Project not found", err)
	}

	assignments := []models.ProjectAssignment{}
	if err := db.DB.Preload("User").Where("project_id = ?", project.ID).Find(&assignments).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch supervisors", err)
	}

	response := []SupervisorLocationResponse{}
	for _, assignment := range assignments {
		user := assignment.User
		dist := haversine(project.Latitude, project.Longitude, user.LastLatitude, user.LastLongitude)

		updateTime := ""
		if user.LastLocationUpdate != nil {
			updateTime = user.LastLocationUpdate.Format("2006-01-02 15:04:05")
		}

		response = append(response, SupervisorLocationResponse{
			UserID:             user.ID,
			Name:               user.Name,
			Email:              user.Email,
			LastLatitude:       user.LastLatitude,
			LastLongitude:      user.LastLongitude,
			LastLocationUpdate: updateTime,
			DistanceFromSiteKm: dist,
		})
	}

	return c.JSON(response)
}
