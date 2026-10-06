package projects

import (
	"testing"
)

func TestCreateProjectInput(t *testing.T) {
	input := CreateProjectRequest{
		Name:        "Test Project",
		Description: "A test project",
		Location:    "Sector 1",
	}

	if input.Name != "Test Project" {
		t.Errorf("Name = %q; want %q", input.Name, "Test Project")
	}
	if input.Description != "A test project" {
		t.Errorf("Description = %q; want %q", input.Description, "A test project")
	}
}
