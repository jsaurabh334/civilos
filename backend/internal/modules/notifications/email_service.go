package notifications

import (
	"fmt"
	"log/slog"
	"net/smtp"
	"os"
)

type EmailService struct{}

var Email = &EmailService{}

func (s *EmailService) SendOTPEmail(toEmail, otp string) error {
	subject := "Your CivilOS OTP Code"
	body := fmt.Sprintf(`<h2>CivilOS OTP Verification</h2>
<p>Your one-time password is: <strong>%s</strong></p>
<p>This OTP expires in 10 minutes.</p>
<p>If you did not request this, please ignore this email.</p>`, otp)
	return s.send(toEmail, subject, body)
}

func (s *EmailService) SendPasswordResetEmail(toEmail, resetLink string) error {
	subject := "CivilOS Password Reset"
	body := fmt.Sprintf(`<h2>CivilOS Password Reset</h2>
<p>Click the link below to reset your password:</p>
<p><a href="%s">%s</a></p>
<p>This link expires in 1 hour.</p>
<p>If you did not request a password reset, please ignore this email.</p>`, resetLink, resetLink)
	return s.send(toEmail, subject, body)
}

func (s *EmailService) send(to, subject, htmlBody string) error {
	host := os.Getenv("SMTP_HOST")
	port := os.Getenv("SMTP_PORT")
	username := os.Getenv("SMTP_USERNAME")
	password := os.Getenv("SMTP_PASSWORD")
	from := os.Getenv("SMTP_FROM")

	if host == "" || port == "" {
		slog.Warn("SMTP not configured, logging email instead",
			slog.String("to", to),
			slog.String("subject", subject))
		return nil
	}

	if username == "" {
		username = from
	}

	auth := smtp.PlainAuth("", username, password, host)
	addr := fmt.Sprintf("%s:%s", host, port)

	msg := fmt.Sprintf("From: %s\r\nTo: %s\r\nSubject: %s\r\nMIME-Version: 1.0\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n%s",
		from, to, subject, htmlBody)

	if err := smtp.SendMail(addr, auth, from, []string{to}, []byte(msg)); err != nil {
		slog.Error("failed to send email",
			slog.String("to", to),
			slog.String("error", err.Error()))
		return fmt.Errorf("failed to send email: %w", err)
	}

	slog.Info("email sent successfully",
		slog.String("to", to),
		slog.String("subject", subject))
	return nil
}
