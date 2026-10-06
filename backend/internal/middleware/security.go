package middleware

import (
	"context"
	"log/slog"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/limiter"
	"github.com/google/uuid"
)

// RequestID attaches a unique request ID to every request for tracing.
func RequestID() fiber.Handler {
	return func(c *fiber.Ctx) error {
		rid := c.Get("X-Request-ID")
		if rid == "" {
			rid = uuid.NewString()
		}
		c.Locals("request_id", rid)
		c.Set("X-Request-ID", rid)
		return c.Next()
	}
}

// StructuredLogger logs each request in JSON format using slog.
func StructuredLogger() fiber.Handler {
	return func(c *fiber.Ctx) error {
		start := time.Now()
		err := c.Next()
		dur := time.Since(start)
		rid, _ := c.Locals("request_id").(string)
		attrs := []slog.Attr{
			slog.String("method", c.Method()),
			slog.String("path", c.Path()),
			slog.Int("status", c.Response().StatusCode()),
			slog.Duration("duration", dur),
			slog.String("ip", c.IP()),
			slog.String("request_id", rid),
		}
		if err != nil {
			attrs = append(attrs, slog.String("error", err.Error()))
		}
		slog.LogAttrs(context.Background(), slog.LevelInfo, "request", attrs...)
		return err
	}
}

// SecurityHeaders injects standard web security headers into all responses
func SecurityHeaders() fiber.Handler {
	return func(c *fiber.Ctx) error {
		c.Set("X-Content-Type-Options", "nosniff")
		c.Set("X-Frame-Options", "DENY")
		c.Set("X-XSS-Protection", "1; mode=block")
		c.Set("Referrer-Policy", "strict-origin-when-cross-origin")
		c.Set("Content-Security-Policy", "default-src 'self'; connect-src 'self' ws: wss:; font-src 'self' https://fonts.gstatic.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; img-src 'self' data: blob: https:; frame-ancestors 'none';")
		return c.Next()
	}
}

// GlobalLimiter limits general requests to 100 per minute per IP
func GlobalLimiter() fiber.Handler {
	return limiter.New(limiter.Config{
		Max:        100,
		Expiration: 1 * time.Minute,
		KeyGenerator: func(c *fiber.Ctx) string {
			return c.IP()
		},
		LimitReached: func(c *fiber.Ctx) error {
			return c.Status(fiber.StatusTooManyRequests).JSON(fiber.Map{
				"error": "Too many requests. Please try again later.",
			})
		},
	})
}

// AuthLimiter limits authentication endpoints to 5 requests per minute per IP
func AuthLimiter() fiber.Handler {
	return limiter.New(limiter.Config{
		Max:        5,
		Expiration: 1 * time.Minute,
		KeyGenerator: func(c *fiber.Ctx) string {
			return c.IP()
		},
		LimitReached: func(c *fiber.Ctx) error {
			return c.Status(fiber.StatusTooManyRequests).JSON(fiber.Map{
				"error": "Too many verification attempts. Please try again in a minute.",
			})
		},
	})
}
