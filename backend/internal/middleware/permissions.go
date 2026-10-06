package middleware

import (
	"encoding/json"
	"strings"

	"civilos/backend/internal/core"
	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

var RolePermissions = map[string][]string{
	"SuperAdmin": {
		"*",
	},
	"ContractorOwner": {
		"projects.read", "projects.write", "projects.delete",
		"diaries.read", "diaries.write", "diaries.approve", "diaries.delete",
		"work_orders.read", "work_orders.write", "work_orders.delete",
		"expenses.read", "expenses.write", "expenses.delete",
		"labor.read", "labor.write", "labor.delete",
		"machinery.read", "machinery.write", "machinery.delete",
		"inventory.read", "inventory.write", "inventory.delete",
		"inspections.read", "inspections.write", "inspections.delete",
		"checklists.read", "checklists.write", "checklists.delete",
		"documents.read", "documents.write", "documents.delete",
		"invoices.read", "invoices.write", "invoices.delete",
		"purchase_orders.read", "purchase_orders.write", "purchase_orders.delete",
		"reports.read",
		"users.invite", "users.manage",
		"settings.read", "settings.write",
	},
	"ProjectManager": {
		"projects.read", "projects.write",
		"diaries.read", "diaries.write", "diaries.approve",
		"work_orders.read", "work_orders.write",
		"expenses.read", "expenses.write",
		"labor.read", "labor.write",
		"machinery.read", "machinery.write",
		"inventory.read", "inventory.write",
		"inspections.read", "inspections.write",
		"checklists.read", "checklists.write",
		"documents.read", "documents.write",
		"invoices.read", "invoices.write",
		"purchase_orders.read", "purchase_orders.write",
		"reports.read",
	},
	"SiteEngineer": {
		"projects.read",
		"diaries.read", "diaries.write",
		"work_orders.read",
		"expenses.read", "expenses.write",
		"labor.read",
		"machinery.read",
		"inventory.read",
		"inspections.read", "inspections.write",
		"checklists.read", "checklists.write",
		"documents.read",
		"reports.read",
	},
}

func RequirePermission(permission string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		roleVal := c.Locals("role")
		if roleVal == nil {
			return core.SendStandardError(c, fiber.StatusUnauthorized, "User role not found", "UNAUTHORIZED", nil)
		}

		role := roleVal.(string)
		perms, ok := RolePermissions[role]
		if !ok {
			return core.SendStandardError(c, fiber.StatusForbidden, "Unknown role", "FORBIDDEN", nil)
		}

		for _, p := range perms {
			if p == "*" || p == permission {
				return c.Next()
			}
		}

		return core.SendStandardError(c, fiber.StatusForbidden, "Access denied: "+permission+" required", "FORBIDDEN", nil)
	}
}

func RequireAnyPermission(permissions ...string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		roleVal := c.Locals("role")
		if roleVal == nil {
			return core.SendStandardError(c, fiber.StatusUnauthorized, "User role not found", "UNAUTHORIZED", nil)
		}

		role := roleVal.(string)
		userPerms, ok := RolePermissions[role]
		if !ok {
			return core.SendStandardError(c, fiber.StatusForbidden, "Unknown role", "FORBIDDEN", nil)
		}

		for _, p := range userPerms {
			if p == "*" {
				return c.Next()
			}
			for _, required := range permissions {
				if p == required {
					return c.Next()
				}
			}
		}

		return core.SendStandardError(c, fiber.StatusForbidden, "Access denied. One of: "+strings.Join(permissions, ", ")+" required", "FORBIDDEN", nil)
	}
}

func FeatureFlag(featureName string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		roleVal := c.Locals("role")
		if roleVal != nil && roleVal.(string) == "SuperAdmin" {
			return c.Next()
		}

		tenantID := c.Locals("tenant_id_value").(uint)
		var tenant models.Tenant
		if err := db.DB.First(&tenant, tenantID).Error; err != nil {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Tenant not found"})
		}

		if tenant.FeatureFlags != "" {
			var flags map[string]bool
			if err := json.Unmarshal([]byte(tenant.FeatureFlags), &flags); err == nil {
				if enabled, ok := flags[featureName]; ok && !enabled {
					return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
						"error": "Feature '" + featureName + "' is not enabled for your workspace",
					})
				}
			}
		}

		return c.Next()
	}
}
