package auth

import (
	"log/slog"
)

type FCMService struct {
}

var FCM = &FCMService{}

// SendPushNotification sends a push notification to the given token.
// In a real application, this would use firebase.google.com/go/v4
func (s *FCMService) SendPushNotification(userID uint, fcmToken, title, body string) error {
	if fcmToken == "" {
		slog.Warn("fcm token missing, skipping push notification", slog.Int("user_id", int(userID)))
		return nil
	}

	// Mock logic
	slog.Info("sending FCM push notification",
		slog.Int("user_id", int(userID)),
		slog.String("fcm_token", fcmToken),
		slog.String("title", title),
		slog.String("body", body),
	)

	return nil
}
