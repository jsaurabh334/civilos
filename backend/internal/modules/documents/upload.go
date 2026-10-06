package documents

import (
	"civilos/backend/internal/core"
	"context"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/gofiber/fiber/v2"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type UploadResponse struct {
	URL  string `json:"url"`
	Name string `json:"name"`
	Size int64  `json:"size"`
}

func UploadFile(c *fiber.Ctx) error {
	file, err := c.FormFile("file")
	if err != nil {
		return core.SendError(c, fiber.StatusBadRequest, "No file uploaded", err)
	}

	subdir := c.FormValue("subdir", "general")
	ext := filepath.Ext(file.Filename)
	fileName := fmt.Sprintf("%d%s", time.Now().UnixNano(), ext)
	objectKey := fmt.Sprintf("%s/%s", subdir, fileName)

	accountID := os.Getenv("R2_ACCOUNT_ID")
	accessKey := os.Getenv("R2_ACCESS_KEY")
	secretKey := os.Getenv("R2_SECRET_KEY")
	bucket := os.Getenv("R2_BUCKET_NAME")
	customDomain := os.Getenv("R2_CUSTOM_DOMAIN")

	if accountID != "" && accessKey != "" && secretKey != "" && bucket != "" {
		cfg, err := config.LoadDefaultConfig(context.TODO(),
			config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(accessKey, secretKey, "")),
			config.WithRegion("auto"),
		)
		if err != nil {
			return core.SendError(c, fiber.StatusInternalServerError, "Failed to load R2 config", err)
		}

		client := s3.NewFromConfig(cfg, func(o *s3.Options) {
			o.BaseEndpoint = aws.String(fmt.Sprintf("https://%s.r2.cloudflarestorage.com", accountID))
		})

		src, err := file.Open()
		if err != nil {
			return core.SendError(c, fiber.StatusInternalServerError, "Failed to open file", err)
		}
		defer src.Close()

		_, err = client.PutObject(context.TODO(), &s3.PutObjectInput{
			Bucket:      aws.String(bucket),
			Key:         aws.String(objectKey),
			Body:        src,
			ContentType: aws.String(file.Header.Get("Content-Type")),
		})

		if err != nil {
			return core.SendError(c, fiber.StatusInternalServerError, "Failed to upload to R2", err)
		}

		var fileURL string
		if customDomain != "" {
			fileURL = fmt.Sprintf("%s/%s", customDomain, objectKey)
		} else {
			fileURL = fmt.Sprintf("https://pub-%s.r2.dev/%s", accountID, objectKey)
		}

		return c.Status(fiber.StatusCreated).JSON(UploadResponse{
			URL:  fileURL,
			Name: file.Filename,
			Size: file.Size,
		})
	}

	uploadsDir := filepath.Join("./uploads", subdir)
	if err := os.MkdirAll(uploadsDir, os.ModePerm); err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to create upload directory", err)
	}

	savePath := filepath.Join(uploadsDir, fileName)
	if err := c.SaveFile(file, savePath); err != nil {
		return core.SendError(c, fiber.StatusInternalServerError, "Failed to save file", err)
	}

	fileURL := fmt.Sprintf("/uploads/%s/%s", subdir, fileName)
	return c.Status(fiber.StatusCreated).JSON(UploadResponse{
		URL:  fileURL,
		Name: file.Filename,
		Size: file.Size,
	})
}
