package core

import (
	"html"
	"log"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

type ErrorResponse struct {
	Success   bool        `json:"success"`
	Error     string      `json:"error"`
	Code      string      `json:"code,omitempty"`
	Details   interface{} `json:"details,omitempty"`
	RequestID string      `json:"request_id,omitempty"`
}

func IsValidDate(d string) bool {
	_, err := time.Parse("2006-01-02", d)
	return err == nil
}

func IsValidMonth(m string) bool {
	_, err := time.Parse("2006-01", m)
	return err == nil
}

func Sanitize(s string) string {
	return html.EscapeString(strings.TrimSpace(s))
}

func GetPagination(c *fiber.Ctx) (int, int) {
	page := 1
	pageSize := 50
	if p := c.Query("page"); p != "" {
		if parsed, err := strconv.Atoi(p); err == nil && parsed > 0 {
			page = parsed
		}
	}
	if ps := c.Query("page_size"); ps != "" {
		if parsed, err := strconv.Atoi(ps); err == nil && parsed > 0 && parsed <= 200 {
			pageSize = parsed
		}
	}
	return (page - 1) * pageSize, pageSize
}

func SendError(c *fiber.Ctx, status int, message string, err error) error {
	var details interface{}
	if err != nil {
		log.Printf("[ERROR] %s: %v", message, err)
		details = map[string]string{"detail": err.Error()}
	}
	return SendStandardError(c, status, message, "", details)
}

func SendStandardError(c *fiber.Ctx, status int, message string, code string, details interface{}) error {
	reqID := ""
	if c.Locals("request_id") != nil {
		reqID = c.Locals("request_id").(string)
	}
	return c.Status(status).JSON(ErrorResponse{
		Success:   false,
		Error:     message,
		Code:      code,
		Details:   details,
		RequestID: reqID,
	})
}

func IsValidPriority(p string) bool {
	valid := map[string]bool{"Low": true, "Medium": true, "High": true, "Critical": true}
	return valid[p]
}

func IsValidWorkOrderStatus(s string) bool {
	valid := map[string]bool{"Open": true, "InProgress": true, "Completed": true, "Cancelled": true}
	return valid[s]
}

func IsValidMachineryStatus(s string) bool {
	valid := map[string]bool{"Active": true, "Maintenance": true, "Idle": true}
	return valid[s]
}

func SetPaginationHeaders(c *fiber.Ctx, total int64) {
	c.Response().Header.Set("X-Total-Count", strconv.FormatInt(total, 10))
	if limit := c.Query("page_size"); limit != "" {
		c.Response().Header.Set("X-Page-Size", limit)
	}
	if page := c.Query("page"); page != "" {
		c.Response().Header.Set("X-Page", page)
	}
}

func ApplySearch(db *gorm.DB, c *fiber.Ctx, fields ...string) *gorm.DB {
	if q := c.Query("q"); q != "" {
		cleaned := Sanitize(q)
		// Escape wildcards to prevent LIKE injection
		cleaned = strings.ReplaceAll(cleaned, "%", "\\%")
		cleaned = strings.ReplaceAll(cleaned, "_", "\\_")

		conditions := make([]string, len(fields))
		args := make([]interface{}, len(fields))
		for i, f := range fields {
			conditions[i] = f + " LIKE ?"
			args[i] = "%" + cleaned + "%"
		}
		db = db.Where(strings.Join(conditions, " OR "), args...)
	}
	return db
}
