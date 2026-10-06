package middleware

import (
	"io"
	"net/http"
	"testing"
	"time"

	"civilos/backend/internal/db"
	"civilos/backend/internal/testutil"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

func TestAuthRequired_WithoutToken(t *testing.T) {
	testutil.SetupTestDB(t)

	app := fiber.New()
	app.Use(AuthRequired)
	app.Get("/test", func(c *fiber.Ctx) error {
		return c.SendString("ok")
	})

	req, _ := http.NewRequest("GET", "/test", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", resp.StatusCode)
	}
}

func TestAuthRequired_WithValidToken(t *testing.T) {
	testutil.SetupTestDB(t)

	tenant := testutil.CreateTestTenant(t)
	user := testutil.CreateTestUser(t, tenant.ID, "Contractor")
	token := GenerateToken(user.ID, user.Email, user.Role, &tenant.ID)

	app := fiber.New()
	app.Use(AuthRequired)
	app.Get("/test", func(c *fiber.Ctx) error {
		uid := c.Locals("user_id").(uint)
		role := c.Locals("role").(string)
		if uid != user.ID {
			t.Fatalf("expected user_id %d, got %d", user.ID, uid)
		}
		if role != "Contractor" {
			t.Fatalf("expected role Contractor, got %s", role)
		}
		return c.SendString("ok")
	})

	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}

	body, _ := io.ReadAll(resp.Body)
	if string(body) != "ok" {
		t.Fatalf("expected body 'ok', got '%s'", string(body))
	}
}

func TestAuthRequired_WithExpiredToken(t *testing.T) {
	testutil.SetupTestDB(t)

	claims := Claims{
		UserID:   1,
		Email:    "test@test.com",
		Role:     "Contractor",
		TenantID: nil,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(-1 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now().Add(-2 * time.Hour)),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenStr, err := token.SignedString(GetJWTSecret())
	if err != nil {
		t.Fatalf("failed to sign expired token: %v", err)
	}

	app := fiber.New()
	app.Use(AuthRequired)
	app.Get("/test", func(c *fiber.Ctx) error {
		return c.SendString("ok")
	})

	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Authorization", "Bearer "+tokenStr)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("expected 401 for expired token, got %d", resp.StatusCode)
	}
}

func TestAuthRequired_WithQueryToken(t *testing.T) {
	testutil.SetupTestDB(t)

	tenant := testutil.CreateTestTenant(t)
	user := testutil.CreateTestUser(t, tenant.ID, "Contractor")
	token := GenerateToken(user.ID, user.Email, user.Role, &tenant.ID)

	app := fiber.New()
	app.Use(AuthRequired)
	app.Get("/test", func(c *fiber.Ctx) error {
		return c.SendString("ok")
	})

	req, _ := http.NewRequest("GET", "/test?token="+token, nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200 with query token, got %d", resp.StatusCode)
	}
}

func TestTenantScope_ForSuperAdmin(t *testing.T) {
	testutil.SetupTestDB(t)

	saToken := GenerateToken(1, "superadmin@civilos.com", "SuperAdmin", nil)

	isTenantScopeCalled := false
	app := fiber.New()
	app.Use(func(c *fiber.Ctx) error {
		c.Locals("role", "SuperAdmin")
		c.Locals("tenant_id", (*uint)(nil))
		return c.Next()
	})
	app.Use(TenantScope)
	app.Get("/test", func(c *fiber.Ctx) error {
		isTenantScopeCalled = true
		tv := c.Locals("tenant_id_value")
		if tv == nil {
			t.Fatal("tenant_id_value should be set for SuperAdmin")
		}
		val, ok := tv.(uint)
		if !ok {
			t.Fatal("tenant_id_value should be uint")
		}
		if val != 0 {
			t.Fatalf("expected tenant_id_value 0 for SuperAdmin, got %d", val)
		}
		return c.SendString("ok")
	})

	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Authorization", "Bearer "+saToken)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200 for SuperAdmin, got %d", resp.StatusCode)
	}
	if !isTenantScopeCalled {
		t.Fatal("next handler should have been called")
	}
}

func TestTenantScope_ForRegularUser(t *testing.T) {
	testutil.SetupTestDB(t)

	tenant := testutil.CreateTestTenant(t)
	user := testutil.CreateTestUser(t, tenant.ID, "Contractor")
	token := GenerateToken(user.ID, user.Email, user.Role, &tenant.ID)

	app := fiber.New()
	app.Use(AuthRequired)
	app.Use(TenantScope)
	app.Get("/test", func(c *fiber.Ctx) error {
		tv := c.Locals("tenant_id_value").(uint)
		if tv != tenant.ID {
			t.Fatalf("expected tenant_id_value %d, got %d", tenant.ID, tv)
		}
		return c.SendString("ok")
	})

	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200 for regular user, got %d", resp.StatusCode)
	}
}

func TestTenantScope_ForInactiveTenant(t *testing.T) {
	testutil.SetupTestDB(t)

	tenant := testutil.CreateTestTenant(t)
	user := testutil.CreateTestUser(t, tenant.ID, "Contractor")
	token := GenerateToken(user.ID, user.Email, user.Role, &tenant.ID)

	db.DB.Model(&tenant).Update("is_active", false)

	app := fiber.New()
	app.Use(AuthRequired)
	app.Use(TenantScope)
	app.Get("/test", func(c *fiber.Ctx) error {
		return c.SendString("ok")
	})

	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusForbidden {
		t.Fatalf("expected 403 for inactive tenant, got %d", resp.StatusCode)
	}
}
