package db

import (
	"civilos/backend/internal/models"
)

// LogAudit saves an audit log to the database
func LogAudit(actor, tenant, action, ip string) {
	log := models.SystemAuditLog{
		Actor:     actor,
		Tenant:    tenant,
		Action:    action,
		IPAddress: ip,
	}
	DB.Create(&log)
}
