package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"
)

func SendFCMPush(userID uint, title, message string) {
	var user models.User
	if err := db.DB.First(&user, userID).Error; err != nil || user.FCMToken == "" {
		return
	}

	fcmPayload := map[string]interface{}{
		"to": user.FCMToken,
		"notification": map[string]string{
			"title": title,
			"body":  message,
			"sound": "default",
		},
		"data": map[string]string{
			"type": "notification",
		},
	}

	payloadBytes, err := json.Marshal(fcmPayload)
	if err != nil {
		return
	}

	req, err := http.NewRequest("POST", "https://fcm.googleapis.com/fcm/send", bytes.NewReader(payloadBytes))
	if err != nil {
		return
	}
	req.Header.Set("Content-Type", "application/json")

	fcmKey := os.Getenv("FCM_SERVER_KEY")
	if fcmKey != "" {
		req.Header.Set("Authorization", "key="+fcmKey)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err == nil {
		resp.Body.Close()
	} else {
		fmt.Printf("[FCM] Failed to send push to user %d: %v\n", userID, err)
	}
}
