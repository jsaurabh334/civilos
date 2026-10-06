package finance

import (
	"fmt"

	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"
	"civilos/backend/internal/modules/notifications"

	"github.com/gofiber/fiber/v2"
)

func ListExpenses(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	expenses := []models.Expense{}
	offset, limit := core.GetPagination(c)
	if err := db.DB.Where("tenant_id = ?", tenantID).Order("expense_date desc").Offset(offset).Limit(limit).Find(&expenses).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to fetch expenses", err)
	}
	return c.JSON(expenses)
}

type CreateExpenseRequest struct {
	Category    string  `json:"category" validate:"required"`
	Amount      float64 `json:"amount" validate:"required,gt=0"`
	Description string  `json:"description"`
	ExpenseDate string  `json:"expense_date" validate:"required"`
	ProjectID   uint    `json:"project_id"`
}

func CreateExpense(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)

	var req CreateExpenseRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	req.Category = core.Sanitize(req.Category)
	req.Description = core.Sanitize(req.Description)
	req.ExpenseDate = core.Sanitize(req.ExpenseDate)

	if !core.IsValidDate(req.ExpenseDate) {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid date format. Expected YYYY-MM-DD", nil)
	}

	if req.ProjectID != 0 {
		var project models.Project
		if err := db.DB.First(&project, req.ProjectID).Error; err != nil {
			return core.SendError(c, fiber.StatusNotFound, "Project not found", nil)
		}
		if project.TenantID != tenantID {
			return core.SendError(c, fiber.StatusForbidden, "Access denied to project", nil)
		}
	}

	expense := models.Expense{
		TenantID:    tenantID,
		Category:    req.Category,
		Amount:      req.Amount,
		Description: req.Description,
		ExpenseDate: req.ExpenseDate,
		ProjectID:   req.ProjectID,
	}

	if err := db.DB.Create(&expense).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to create expense", err)
	}

	notifications.NotifyExpenseCreated(expense)

	// Audit Log
	userID := fmt.Sprintf("%d", c.Locals("user_id").(uint))
	tenantStr := fmt.Sprintf("%d", tenantID)
	db.LogAudit(userID, tenantStr, "Created Expense", c.IP())

	return c.Status(fiber.StatusCreated).JSON(expense)
}

type UpdateExpenseRequest struct {
	Category    string  `json:"category" validate:"omitempty"`
	Description string  `json:"description" validate:"omitempty"`
	Amount      float64 `json:"amount" validate:"omitempty,gt=0"`
	ExpenseDate string  `json:"expense_date" validate:"omitempty"`
}

func UpdateExpense(c *fiber.Ctx) error {
	id := c.Params("id")
	tenantID := c.Locals("tenant_id_value").(uint)

	var expense models.Expense
	if err := db.DB.First(&expense, id).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Expense not found", err)
	}
	if expense.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}

	var req UpdateExpenseRequest
	if err := c.BodyParser(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Invalid request body", err)
	}

	if err := core.ValidateStruct(&req); err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "Validation failed", err)
	}

	req.Category = core.Sanitize(req.Category)
	req.Description = core.Sanitize(req.Description)
	req.ExpenseDate = core.Sanitize(req.ExpenseDate)

	if req.Category != "" {
		expense.Category = req.Category
	}
	if req.Description != "" {
		expense.Description = req.Description
	}
	if req.Amount > 0 {
		expense.Amount = req.Amount
	}
	if req.ExpenseDate != "" && core.IsValidDate(req.ExpenseDate) {
		expense.ExpenseDate = req.ExpenseDate
	}

	if err := db.DB.Save(&expense).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to update expense", err)
	}

	// Audit Log
	userID := fmt.Sprintf("%d", c.Locals("user_id").(uint))
	tenantStr := fmt.Sprintf("%d", tenantID)
	db.LogAudit(userID, tenantStr, "Updated Expense: "+id, c.IP())

	return c.JSON(expense)
}

func DeleteExpense(c *fiber.Ctx) error {
	tenantID := c.Locals("tenant_id_value").(uint)
	expenseID := c.Params("id")

	var expense models.Expense
	if err := db.DB.First(&expense, expenseID).Error; err != nil {
		return core.SendError(c, fiber.StatusNotFound, "Expense not found", err)
	}
	if expense.TenantID != tenantID {
		return core.SendError(c, fiber.StatusForbidden, "Access denied", nil)
	}
	if err := db.DB.Delete(&expense).Error; err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to delete expense", err)
	}
	return c.JSON(fiber.Map{"message": "Expense deleted"})
}
