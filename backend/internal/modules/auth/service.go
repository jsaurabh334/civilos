package auth

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"regexp"
	"strings"
	"time"

	"civilos/backend/internal/db"
	"civilos/backend/internal/middleware"
	"civilos/backend/internal/models"
	"civilos/backend/internal/modules/notifications"
	"golang.org/x/crypto/bcrypt"
)

var (
	ErrInvalidCredentials = errors.New("invalid email or password")
	ErrEmailExists        = errors.New("email already registered")
	ErrSlugExists         = errors.New("company subdomain/slug already in use")
	ErrUserNotFound       = errors.New("user not found")
	ErrTenantInactive     = errors.New("workspace is deactivated")
)

// AuthService handles authentication and user management business logic.
type AuthService struct{}

func (s *AuthService) Login(email, password string) (*models.User, string, error) {
	var user models.User
	if err := db.DB.Preload("Tenant").Where("email = ?", email).First(&user).Error; err != nil {
		return nil, "", ErrInvalidCredentials
	}

	if user.Tenant != nil && !user.Tenant.IsActive {
		return nil, "", ErrTenantInactive
	}

	// Check if account is locked
	if user.LockedUntil != nil && user.LockedUntil.After(time.Now()) {
		return nil, "", errors.New("account locked due to too many failed attempts. Try again later")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		// Increment failed attempts
		user.FailedLoginAttempts++
		if user.FailedLoginAttempts >= 5 {
			lockTime := time.Now().Add(15 * time.Minute)
			user.LockedUntil = &lockTime
		}
		db.DB.Save(&user)
		return nil, "", ErrInvalidCredentials
	}

	// Reset failed attempts on successful login
	if user.FailedLoginAttempts > 0 || user.LockedUntil != nil {
		user.FailedLoginAttempts = 0
		user.LockedUntil = nil
		db.DB.Save(&user)
	}

	token, err := middleware.GenerateToken(user.ID, user.Email, user.Role, user.TenantID)
	if err != nil {
		return nil, "", errors.New("failed to generate token")
	}
	return &user, token, nil
}

func (s *AuthService) Signup(input SignupInput) (*models.User, string, error) {
	input.CompanyName = strings.TrimSpace(input.CompanyName)
	input.OwnerName = strings.TrimSpace(input.OwnerName)
	input.Email = strings.TrimSpace(input.Email)
	input.Slug = strings.TrimSpace(input.Slug)

	if input.CompanyName == "" || input.OwnerName == "" || input.Email == "" {
		return nil, "", errors.New("company name, owner name, and email are required")
	}
	if !ValidatePassword(input.Password) {
		return nil, "", errors.New("password must be at least 8 characters with uppercase, lowercase, digit, and special character")
	}

	var existing models.User
	if err := db.DB.Where("email = ?", input.Email).First(&existing).Error; err == nil {
		return nil, "", ErrEmailExists
	}

	reg, _ := regexp.Compile("[^a-zA-Z0-9-]+")
	slug := reg.ReplaceAllString(strings.ToLower(input.Slug), "")
	if slug == "" {
		slug = reg.ReplaceAllString(strings.ToLower(strings.ReplaceAll(input.CompanyName, " ", "-")), "")
	}

	tx := db.DB.Begin()

	var existingTenant models.Tenant
	if err := tx.Where("slug = ?", slug).First(&existingTenant).Error; err == nil {
		tx.Rollback()
		return nil, "", ErrSlugExists
	}

	tenant := models.Tenant{
		Name:         input.CompanyName,
		Slug:         slug,
		IsActive:     true,
		FeatureFlags: `{"site_diary": true, "inventory": false, "marketplace": true}`,
	}
	if err := tx.Create(&tenant).Error; err != nil {
		tx.Rollback()
		return nil, "", errors.New("failed to create tenant")
	}

	hashedPassword, err := HashPassword(input.Password)
	if err != nil {
		tx.Rollback()
		return nil, "", errors.New("failed to hash password")
	}

	user := models.User{
		Name:         input.OwnerName,
		Email:        input.Email,
		PasswordHash: hashedPassword,
		Role:         "Contractor",
		TenantID:     &tenant.ID,
	}
	if err := tx.Create(&user).Error; err != nil {
		tx.Rollback()
		return nil, "", errors.New("failed to create user")
	}

	project := models.Project{
		Name:        "First Construction Project",
		Description: "Initial setup project",
		Location:    "Headquarters Site",
		TenantID:    tenant.ID,
	}
	if err := tx.Create(&project).Error; err != nil {
		tx.Rollback()
		return nil, "", errors.New("failed to create default project")
	}

	tx.Commit()

	token, err := middleware.GenerateToken(user.ID, user.Email, user.Role, &tenant.ID)
	if err != nil {
		return nil, "", errors.New("tenant registered, but token generation failed")
	}

	user.Tenant = &tenant
	return &user, token, nil
}

func (s *AuthService) ForgotPassword(email string) (string, error) {
	var user models.User
	if err := db.DB.Where("email = ?", email).First(&user).Error; err != nil {
		return "", nil
	}

	tokenBytes := make([]byte, 16)
	if _, err := rand.Read(tokenBytes); err != nil {
		return "", errors.New("failed to generate reset token")
	}
	token := hex.EncodeToString(tokenBytes)
	expiry := time.Now().Add(1 * time.Hour)
	user.PasswordResetToken = token
	user.PasswordResetExpiry = &expiry

	if err := db.DB.Save(&user).Error; err != nil {
		return "", errors.New("failed to save reset token")
	}

	// Send password reset email
	resetLink := fmt.Sprintf("%s/reset-password?token=%s", os.Getenv("APP_URL"), token)
	if err := notifications.Email.SendPasswordResetEmail(email, resetLink); err != nil {
		slog.Error("failed to send password reset email", slog.String("email", email), slog.String("error", err.Error()))
	}

	return token, nil
}

func (s *AuthService) ResetPassword(token, newPassword string) error {
	var user models.User
	if err := db.DB.Where("password_reset_token = ?", token).First(&user).Error; err != nil {
		return errors.New("invalid or expired reset token")
	}
	if user.PasswordResetExpiry == nil || time.Now().After(*user.PasswordResetExpiry) {
		return errors.New("reset token has expired")
	}

	hashedPassword, err := HashPassword(newPassword)
	if err != nil {
		return errors.New("failed to hash password")
	}

	user.PasswordHash = hashedPassword
	user.PasswordResetToken = ""
	user.PasswordResetExpiry = nil

	return db.DB.Save(&user).Error
}

func (s *AuthService) ChangePassword(userID uint, currentPassword, newPassword string) error {
	var user models.User
	if err := db.DB.First(&user, userID).Error; err != nil {
		return ErrUserNotFound
	}
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(currentPassword)); err != nil {
		return errors.New("current password is incorrect")
	}

	newHash, err := HashPassword(newPassword)
	if err != nil {
		return errors.New("failed to hash new password")
	}
	user.PasswordHash = newHash
	return db.DB.Save(&user).Error
}

func (s *AuthService) InviteUser(tenantID uint, input InviteUserInput) (*models.User, error) {
	validRoles := map[string]bool{"Supervisor": true, "Vendor": true, "Contractor": true}
	if !validRoles[input.Role] {
		return nil, errors.New("role must be: Supervisor, Vendor, or Contractor")
	}

	password := input.Password
	if password == "" {
		password = "Welcome@123"
	}
	if !ValidatePassword(password) {
		return nil, errors.New("password must meet strength requirements")
	}

	var existing models.User
	if err := db.DB.Where("email = ?", input.Email).First(&existing).Error; err == nil {
		return nil, ErrEmailExists
	}

	hash, err := HashPassword(password)
	if err != nil {
		return nil, err
	}

	user := models.User{
		Name:         input.Name,
		Email:        input.Email,
		PasswordHash: hash,
		Role:         input.Role,
		TenantID:     &tenantID,
	}
	if err := db.DB.Create(&user).Error; err != nil {
		return nil, errors.New("failed to create user")
	}
	return &user, nil
}

func (s *AuthService) ListUsers(tenantID uint, offset, limit int) ([]models.User, error) {
	users := make([]models.User, 0)
	if err := db.DB.Where("tenant_id = ?", tenantID).Offset(offset).Limit(limit).Find(&users).Error; err != nil {
		return nil, errors.New("failed to fetch users")
	}
	for i := range users {
		users[i].PasswordHash = ""
	}
	return users, nil
}

func (s *AuthService) GetUser(userID uint) (*models.User, error) {
	var user models.User
	if err := db.DB.Preload("Tenant").First(&user, userID).Error; err != nil {
		return nil, ErrUserNotFound
	}
	return &user, nil
}

func (s *AuthService) UpdateProfile(userID uint, name, phone string) (*models.User, error) {
	var user models.User
	if err := db.DB.First(&user, userID).Error; err != nil {
		return nil, ErrUserNotFound
	}
	user.Name = name
	user.Phone = phone
	if err := db.DB.Save(&user).Error; err != nil {
		return nil, errors.New("failed to update profile")
	}
	return &user, nil
}

func (s *AuthService) DeleteUser(tenantID, userID, requesterID uint) error {
	var user models.User
	if err := db.DB.First(&user, userID).Error; err != nil {
		return ErrUserNotFound
	}
	if user.TenantID == nil || *user.TenantID != tenantID {
		return errors.New("access denied")
	}
	if user.ID == requesterID {
		return errors.New("cannot delete your own account")
	}
	db.DB.Where("user_id = ?", user.ID).Delete(&models.ProjectAssignment{})
	db.DB.Where("sender_id = ?", user.ID).Delete(&models.GroupMessage{})
	db.DB.Where("sender_id = ?", user.ID).Delete(&models.TicketMessage{})
	db.DB.Where("supervisor_id = ?", user.ID).Delete(&models.SupervisorLocation{})

	if err := db.DB.Delete(&user).Error; err != nil {
		return errors.New("failed to delete user")
	}
	return nil
}

func (s *AuthService) UpdateUser(tenantID uint, userID string, name, role, phone string) (*models.User, error) {
	var user models.User
	if err := db.DB.First(&user, userID).Error; err != nil {
		return nil, ErrUserNotFound
	}
	if user.TenantID == nil || *user.TenantID != tenantID {
		return nil, errors.New("access denied")
	}
	if name != "" {
		user.Name = name
	}
	if role != "" {
		validRoles := map[string]bool{"Contractor": true, "Supervisor": true, "Vendor": true}
		if validRoles[role] {
			user.Role = role
		}
	}
	if phone != "" {
		user.Phone = phone
	}
	if err := db.DB.Save(&user).Error; err != nil {
		return nil, errors.New("failed to update user")
	}
	return &user, nil
}

type SignupInput struct {
	CompanyName string
	Slug        string
	OwnerName   string
	Email       string
	Password    string
}

type InviteUserInput struct {
	Name     string
	Email    string
	Password string
	Role     string
}

func ValidatePassword(password string) bool {
	if len(password) < 8 {
		return false
	}
	var hasUpper, hasLower, hasDigit, hasSpecial bool
	for _, char := range password {
		switch {
		case 'a' <= char && char <= 'z':
			hasLower = true
		case 'A' <= char && char <= 'Z':
			hasUpper = true
		case '0' <= char && char <= '9':
			hasDigit = true
		default:
			hasSpecial = true
		}
	}
	return hasUpper && hasLower && hasDigit && hasSpecial
}

func HashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(hash), nil
}
