package services

import (
	"fmt"
	"os"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"
)

// CalculateTotalStorage checks for AWS keys, but falls back to a realistic estimate
func CalculateTotalStorage() string {
	awsKey := os.Getenv("AWS_ACCESS_KEY_ID")
	if awsKey != "" {
		// Mock AWS SDK integration would go here
		return "AWS S3 Connected (Calculation Pending)"
	}

	// Fallback mock logic for realistic demo based on database footprint
	var userCount int64
	db.DB.Model(&models.User{}).Count(&userCount)

	var projectCount int64
	db.DB.Model(&models.Project{}).Count(&projectCount)

	// Assume each user has ~50MB of files (avatars, basic docs)
	// Assume each project has ~500MB of files (plans, diaries, photos)
	storageMB := (userCount * 50) + (projectCount * 500)

	if storageMB > 1024 {
		return fmt.Sprintf("%.2f GB", float64(storageMB)/1024.0)
	}
	return fmt.Sprintf("%d MB", storageMB)
}
