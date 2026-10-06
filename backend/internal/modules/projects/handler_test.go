package projects

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"testing"

	"civilos/backend/internal/db"
	"civilos/backend/internal/middleware"
	"civilos/backend/internal/models"
	"civilos/backend/internal/testutil"

	"github.com/gofiber/fiber/v2"
)

func setupProjectsApp(t *testing.T) (*fiber.App, models.Tenant, models.User, string) {
	t.Helper()
	testutil.SetupTestDB(t)

	tenant := testutil.CreateTestTenant(t)
	user := testutil.CreateTestUser(t, tenant.ID, "Contractor")
	token := testutil.GenerateTestToken(user.ID, user.Email, user.Role, &tenant.ID)

	app := fiber.New()

	protected := app.Group("", middleware.AuthRequired, middleware.TenantScope)
	protected.Get("/projects", ListProjects)
	protected.Post("/projects", CreateProject)
	protected.Get("/projects/:projectId", GetProject)
	protected.Delete("/projects/:projectId", DeleteProject)

	return app, tenant, user, token
}

func setupProjectsAppNoRole(t *testing.T) (*fiber.App, models.Tenant, models.User, string) {
	t.Helper()
	testutil.SetupTestDB(t)

	tenant := testutil.CreateTestTenant(t)
	user := testutil.CreateTestUser(t, tenant.ID, "Supervisor")
	token := testutil.GenerateTestToken(user.ID, user.Email, user.Role, &tenant.ID)

	app := fiber.New()

	protected := app.Group("", middleware.AuthRequired, middleware.TenantScope)
	protected.Post("/projects", CreateProject)
	protected.Get("/projects", ListProjects)

	return app, tenant, user, token
}

func TestListProjects_TenantScoped(t *testing.T) {
	app, tenant, _, token := setupProjectsApp(t)

	project1 := testutil.CreateTestProject(t, tenant.ID, "Project Alpha")
	project2 := testutil.CreateTestProject(t, tenant.ID, "Project Beta")

	otherTenant := testutil.CreateTestTenant(t)
	_ = testutil.CreateTestProject(t, otherTenant.ID, "Other Tenant Project")

	req, _ := http.NewRequest("GET", "/projects", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}

	var projects []models.Project
	data, _ := io.ReadAll(resp.Body)
	json.Unmarshal(data, &projects)

	if len(projects) != 2 {
		t.Fatalf("expected 2 projects for tenant, got %d", len(projects))
	}

	found := false
	for _, p := range projects {
		if p.ID == project1.ID || p.ID == project2.ID {
			found = true
		}
		if p.Name == "Other Tenant Project" {
			t.Fatal("should not return projects from other tenant")
		}
	}
	if !found {
		t.Fatal("expected projects from the tenant")
	}
}

func TestCreateProject_ByContractor_Success(t *testing.T) {
	app, _, _, token := setupProjectsApp(t)

	body, _ := json.Marshal(CreateProjectRequest{
		Name:     "New Construction Project",
		Location: "Site Location Alpha",
	})
	req, _ := http.NewRequest("POST", "/projects", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("expected 201, got %d", resp.StatusCode)
	}

	var project models.Project
	data, _ := io.ReadAll(resp.Body)
	json.Unmarshal(data, &project)

	if project.Name != "New Construction Project" {
		t.Fatalf("expected project name, got %s", project.Name)
	}
	if project.Location != "Site Location Alpha" {
		t.Fatalf("expected location, got %s", project.Location)
	}

	var count int64
	db.DB.Model(&models.Project{}).Where("id = ?", project.ID).Count(&count)
	if count != 1 {
		t.Fatal("project should be persisted in database")
	}
}

func TestCreateProject_ByNonContractor_Success(t *testing.T) {
	app, _, _, token := setupProjectsAppNoRole(t)

	body, _ := json.Marshal(CreateProjectRequest{
		Name:     "Project by Supervisor",
		Location: "Some Location",
	})
	req, _ := http.NewRequest("POST", "/projects", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("expected 201 (no role check on create), got %d", resp.StatusCode)
	}
}

func TestCreateProject_InvalidData(t *testing.T) {
	app, _, _, token := setupProjectsApp(t)

	body, _ := json.Marshal(CreateProjectRequest{
		Name: "",
	})
	req, _ := http.NewRequest("POST", "/projects", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", resp.StatusCode)
	}
}

func TestGetProject_ByID(t *testing.T) {
	app, tenant, _, token := setupProjectsApp(t)

	project := testutil.CreateTestProject(t, tenant.ID, "Specific Project")

	req, _ := http.NewRequest("GET", "/projects/"+string(rune(project.ID+'0')), nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode == http.StatusNotFound {
		// The ID may need to be numeric; try with proper string format
		req2, _ := http.NewRequest("GET", fmt.Sprintf("/projects/%d", project.ID), nil)
		req2.Header.Set("Authorization", "Bearer "+token)
		resp2, err2 := app.Test(req2)
		if err2 != nil {
			t.Fatalf("request failed: %v", err2)
		}
		if resp2.StatusCode != http.StatusOK {
			t.Fatalf("expected 200, got %d", resp2.StatusCode)
		}
		var result models.Project
		data, _ := io.ReadAll(resp2.Body)
		json.Unmarshal(data, &result)
		if result.ID != project.ID {
			t.Fatalf("expected project ID %d, got %d", project.ID, result.ID)
		}
	} else if resp.StatusCode == http.StatusOK {
		var result models.Project
		data, _ := io.ReadAll(resp.Body)
		json.Unmarshal(data, &result)
		if result.ID != project.ID {
			t.Fatalf("expected project ID %d, got %d", project.ID, result.ID)
		}
	} else {
		t.Fatalf("unexpected status: %d", resp.StatusCode)
	}
}

func TestDeleteProject_ByOwner(t *testing.T) {
	app, tenant, _, token := setupProjectsApp(t)

	project := testutil.CreateTestProject(t, tenant.ID, "Project To Delete")

	req, _ := http.NewRequest("DELETE", fmt.Sprintf("/projects/%d", project.ID), nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}

	var count int64
	db.DB.Model(&models.Project{}).Where("id = ?", project.ID).Count(&count)
	if count != 0 {
		t.Fatal("project should be deleted from database")
	}
}

func TestGetProject_NotFound(t *testing.T) {
	app, _, _, token := setupProjectsApp(t)

	req, _ := http.NewRequest("GET", "/projects/99999", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusNotFound {
		t.Fatalf("expected 404, got %d", resp.StatusCode)
	}
}
