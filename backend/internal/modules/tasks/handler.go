package tasks

import (
	"civilos/backend/internal/core"
	"strconv"
	"time"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func ListTasks(c *fiber.Ctx) error {
	projectID := c.QueryInt("project_id", 0)
	if projectID == 0 {
		return core.SendError(c, fiber.StatusBadRequest, "project_id query param required", nil)
	}

	tasks := make([]models.ProjectTask, 0)
	if err := db.DB.Where("project_id = ?", projectID).
		Order("start_date ASC, id ASC").
		Find(&tasks).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch tasks", err)
	}
	return c.JSON(tasks)
}

func CreateTask(c *fiber.Ctx) error {
	var task models.ProjectTask
	if err := c.BodyParser(&task); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request", err)
	}
	if task.Title == "" || task.StartDate == "" || task.EndDate == "" {
		return core.SendError(c, fiber.StatusBadRequest, "title, start_date, end_date required", nil)
	}

	// Calculate duration
	start, _ := time.Parse("2006-01-02", task.StartDate)
	end, _ := time.Parse("2006-01-02", task.EndDate)
	if !end.IsZero() && !start.IsZero() {
		task.DurationDays = int(end.Sub(start).Hours()/24) + 1
	}
	if task.DurationDays <= 0 {
		task.DurationDays = 1
	}

	if err := db.DB.Create(&task).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to create task", err)
	}
	return c.Status(fiber.StatusCreated).JSON(task)
}

func UpdateTask(c *fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 64)
	if err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid task ID", err)
	}

	var existing models.ProjectTask
	if err := db.DB.First(&existing, id).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Task not found", err)
	}

	var body struct {
		Title         *string  `json:"title"`
		Description   *string  `json:"description"`
		Assignee      *string  `json:"assignee"`
		StartDate     *string  `json:"start_date"`
		EndDate       *string  `json:"end_date"`
		Progress      *float64 `json:"progress"`
		Priority      *string  `json:"priority"`
		Status        *string  `json:"status"`
		DependencyIDs *string  `json:"dependency_ids"`
		ParentID      *uint    `json:"parent_id"`
	}
	if err := c.BodyParser(&body); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request", err)
	}

	updates := map[string]interface{}{}
	if body.Title != nil {
		updates["title"] = *body.Title
	}
	if body.Description != nil {
		updates["description"] = *body.Description
	}
	if body.Assignee != nil {
		updates["assignee"] = *body.Assignee
	}
	if body.StartDate != nil {
		updates["start_date"] = *body.StartDate
	}
	if body.EndDate != nil {
		updates["end_date"] = *body.EndDate
	}
	if body.Progress != nil {
		updates["progress"] = *body.Progress
	}
	if body.Priority != nil {
		updates["priority"] = *body.Priority
	}
	if body.Status != nil {
		updates["status"] = *body.Status
	}
	if body.DependencyIDs != nil {
		updates["dependency_ids"] = *body.DependencyIDs
	}
	if body.ParentID != nil {
		updates["parent_id"] = *body.ParentID
	}

	// Recalculate duration if dates changed
	if body.StartDate != nil || body.EndDate != nil {
		sd := existing.StartDate
		ed := existing.EndDate
		if body.StartDate != nil && *body.StartDate != "" {
			sd = *body.StartDate
		}
		if body.EndDate != nil && *body.EndDate != "" {
			ed = *body.EndDate
		}
		start, _ := time.Parse("2006-01-02", sd)
		end, _ := time.Parse("2006-01-02", ed)
		if !end.IsZero() && !start.IsZero() {
			updates["duration_days"] = int(end.Sub(start).Hours()/24) + 1
		}
	}

	if err := db.DB.Model(&existing).Updates(updates).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update task", err)
	}

	db.DB.First(&existing, id)
	return c.JSON(existing)
}

func DeleteTask(c *fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 64)
	if err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid task ID", err)
	}

	result := db.DB.Delete(&models.ProjectTask{}, id)
	if result.RowsAffected == 0 {
		return core.SendError(c, fiber.StatusNotFound, "Task not found", nil)
	}
	return c.JSON(fiber.Map{"message": "Task deleted"})
}

func ReorderTasks(c *fiber.Ctx) error {
	var body struct {
		Tasks []struct {
			ID        uint   `json:"id"`
			StartDate string `json:"start_date"`
			EndDate   string `json:"end_date"`
		} `json:"tasks"`
	}
	if err := c.BodyParser(&body); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request", err)
	}

	for _, t := range body.Tasks {
		start, _ := time.Parse("2006-01-02", t.StartDate)
		end, _ := time.Parse("2006-01-02", t.EndDate)
		duration := 1
		if !end.IsZero() && !start.IsZero() {
			duration = int(end.Sub(start).Hours()/24) + 1
		}
		db.DB.Model(&models.ProjectTask{}).Where("id = ?", t.ID).Updates(map[string]interface{}{
			"start_date":    t.StartDate,
			"end_date":      t.EndDate,
			"duration_days": duration,
		})
	}

	return c.JSON(fiber.Map{"message": "Tasks reordered"})
}
