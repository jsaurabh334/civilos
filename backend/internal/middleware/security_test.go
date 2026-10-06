package middleware

import (
	"net/http/httptest"
	"testing"

	"github.com/gofiber/fiber/v2"
)

func TestSecurityHeaders(t *testing.T) {
	app := fiber.New()
	app.Use(SecurityHeaders())
	app.Get("/test", func(c *fiber.Ctx) error {
		return c.SendString("ok")
	})

	req := httptest.NewRequest("GET", "/test", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Failed to execute request: %v", err)
	}

	headers := []struct {
		key   string
		value string
	}{
		{"X-Content-Type-Options", "nosniff"},
		{"X-Frame-Options", "DENY"},
		{"X-XSS-Protection", "1; mode=block"},
		{"Referrer-Policy", "strict-origin-when-cross-origin"},
		{"Content-Security-Policy", "default-src 'self'; connect-src 'self' ws: wss:; font-src 'self' https://fonts.gstatic.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; img-src 'self' data: blob: https:; frame-ancestors 'none';"},
	}

	for _, h := range headers {
		got := resp.Header.Get(h.key)
		if got != h.value {
			t.Errorf("Header %s = %q; want %q", h.key, got, h.value)
		}
	}
}
