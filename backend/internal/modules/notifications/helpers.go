package notifications

import (
	"encoding/json"
	"fmt"
	"log"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"
	"civilos/backend/internal/services"
	"civilos/backend/internal/ws"
)

func createNotification(userID uint, title, message, ntype string, relatedID *uint) {
	notif := models.Notification{
		UserID:    userID,
		Title:     title,
		Message:   message,
		Type:      ntype,
		Read:      false,
		RelatedID: relatedID,
	}
	if err := db.DB.Create(&notif).Error; err != nil {
		log.Printf("[NOTIFICATION] Failed to create notification: %v", err)
		return
	}
	notifJSON, err := json.Marshal(notif)
	if err == nil {
		ws.GlobalHub.SendToUser(userID, notifJSON)
	}

	go services.SendFCMPush(userID, title, message)
}

func notifyProjectOwner(projectID uint, title, message, ntype string) {
	var project models.Project
	if err := db.DB.First(&project, projectID).Error; err != nil {
		return
	}
	users := make([]models.User, 0)
	db.DB.Where("tenant_id = ? AND role IN ?", project.TenantID, []string{"Contractor"}).Find(&users)
	for _, u := range users {
		createNotification(u.ID, title, message, ntype, &projectID)
	}
}

func notifyUserByRole(tenantID uint, role string, title, message, ntype string, relatedID *uint) {
	users := make([]models.User, 0)
	db.DB.Where("tenant_id = ? AND role = ?", tenantID, role).Find(&users)
	for _, u := range users {
		createNotification(u.ID, title, message, ntype, relatedID)
	}
}

func notifyUser(userID uint, title, message string) {
	createNotification(userID, title, message, "info", nil)
}

func NotifyWorkOrderAssigned(wo models.WorkOrder) {
	notifyProjectOwner(wo.ProjectID,
		fmt.Sprintf("Work Order: %s", wo.Title),
		fmt.Sprintf("New work order '%s' has been created with %s priority.", wo.Title, wo.Priority),
		"work_order",
	)
}

func NotifyDiaryApproved(diaryID uint, projectID uint, engineerName string) {
	notifyProjectOwner(projectID,
		"Diary Entry Approved",
		fmt.Sprintf("Site diary entry by %s has been approved.", engineerName),
		"diary",
	)
}

func NotifyExpenseCreated(expense models.Expense) {
	notifyProjectOwner(expense.ProjectID,
		"New Expense Recorded",
		fmt.Sprintf("Expense of ₹%.2f has been recorded under %s.", expense.Amount, expense.Category),
		"expense",
	)
}
