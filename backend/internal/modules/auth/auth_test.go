package auth

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"testing"
	"time"

	"civilos/backend/internal/db"
	"civilos/backend/internal/middleware"
	"civilos/backend/internal/models"
	"civilos/backend/internal/testutil"

	"github.com/gofiber/fiber/v2"
)

func setupAuthApp(t *testing.T) (*fiber.App, models.Tenant, models.User, string) {
	t.Helper()
	testutil.SetupTestDB(t)

	tenant := testutil.CreateTestTenant(t)
	user := testutil.CreateTestUser(t, tenant.ID, "Contractor")
	token := testutil.GenerateTestToken(user.ID, user.Email, user.Role, &tenant.ID)

	app := fiber.New()

	app.Post("/auth/login", Login)
	app.Post("/auth/signup", SignupTenant)

	protected := app.Group("", middleware.AuthRequired, middleware.TenantScope)
	protected.Get("/auth/me", GetMe)
	protected.Put("/auth/password", ChangePassword)

	return app, tenant, user, token
}

func TestLoginSuccess(t *testing.T) {
	app, _, user, _ := setupAuthApp(t)

	body, _ := json.Marshal(LoginRequest{Email: user.Email, Password: "Password123"})
	req, _ := http.NewRequest("POST", "/auth/login", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
	var result map[string]interface{}
	data, _ := io.ReadAll(resp.Body)
	json.Unmarshal(data, &result)
	if result["token"] == nil {
		t.Fatal("expected token in response")
	}
	if result["user"] == nil {
		t.Fatal("expected user in response")
	}
}

func TestLoginWrongPassword(t *testing.T) {
	app, _, user, _ := setupAuthApp(t)

	body, _ := json.Marshal(LoginRequest{Email: user.Email, Password: "WrongPassword1!"})
	req, _ := http.NewRequest("POST", "/auth/login", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", resp.StatusCode)
	}
}

func TestLoginInactiveTenant(t *testing.T) {
	testutil.SetupTestDB(t)

	tenant := testutil.CreateTestTenant(t)
	db.DB.Model(&tenant).Update("is_active", false)
	user := testutil.CreateTestUser(t, tenant.ID, "Contractor")

	app := fiber.New()
	app.Post("/auth/login", Login)

	body, _ := json.Marshal(LoginRequest{Email: user.Email, Password: "Password123"})
	req, _ := http.NewRequest("POST", "/auth/login", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusForbidden {
		t.Fatalf("expected 403, got %d", resp.StatusCode)
	}
}

func TestSignupSuccess(t *testing.T) {
	testutil.SetupTestDB(t)

	app := fiber.New()
	app.Post("/auth/signup", SignupTenant)

	suffix := fmt.Sprintf("%d", time.Now().UnixNano())
	body, _ := json.Marshal(SignupRequest{
		CompanyName: "TestCo " + suffix,
		Slug:        "testco-" + suffix,
		OwnerName:   "Test Owner " + suffix,
		Email:       "owner+" + suffix + "@test.com",
		Password:    "Password123#",
	})
	req, _ := http.NewRequest("POST", "/auth/signup", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("expected 201, got %d", resp.StatusCode)
	}
	var result map[string]interface{}
	data, _ := io.ReadAll(resp.Body)
	json.Unmarshal(data, &result)
	if result["token"] == nil {
		t.Fatal("expected token in signup response")
	}
}

func TestGetMeWithValidToken(t *testing.T) {
	app, _, user, token := setupAuthApp(t)

	req, _ := http.NewRequest("GET", "/auth/me", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
	var result map[string]interface{}
	data, _ := io.ReadAll(resp.Body)
	json.Unmarshal(data, &result)
	if result["email"] != user.Email {
		t.Fatalf("expected email %s, got %v", user.Email, result["email"])
	}
}

func TestGetMeWithoutToken(t *testing.T) {
	app, _, _, _ := setupAuthApp(t)

	req, _ := http.NewRequest("GET", "/auth/me", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", resp.StatusCode)
	}
}

func TestChangePasswordSuccess(t *testing.T) {
	app, _, _, token := setupAuthApp(t)

	body, _ := json.Marshal(ChangePasswordRequest{
		CurrentPassword: "Password123",
		NewPassword:     "NewPass123#",
	})
	req, _ := http.NewRequest("PUT", "/auth/password", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestChangePasswordWrongCurrent(t *testing.T) {
	app, _, _, token := setupAuthApp(t)

	body, _ := json.Marshal(ChangePasswordRequest{
		CurrentPassword: "WrongPassword1!",
		NewPassword:     "NewPass123#",
	})
	req, _ := http.NewRequest("PUT", "/auth/password", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", resp.StatusCode)
	}
}
