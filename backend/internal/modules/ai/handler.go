package ai

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"os"
	"time"

	"civilos/backend/internal/db"
	"civilos/backend/internal/models"

	"github.com/gofiber/fiber/v2"
	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/option"
)

// OCRExtract handles processing of images for invoices/BOQs
func OCRExtract(c *fiber.Ctx) error {
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		return c.Status(500).JSON(fiber.Map{"error": "Gemini API key is not configured"})
	}

	file, err := c.FormFile("image")
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Image file is required"})
	}

	f, err := file.Open()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to open image file"})
	}
	defer f.Close()

	imgData, err := io.ReadAll(f)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to read image data"})
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to initialize AI client"})
	}
	defer client.Close()

	model := client.GenerativeModel("gemini-1.5-flash")
	prompt := genai.Text("Extract all text from this image. If it's an invoice, extract the total amount, tax, and line items. If it's a BOQ, extract the items and quantities. Output in JSON format.")
	imgPart := genai.ImageData("image/jpeg", imgData) // Assuming JPEG for now

	resp, err := model.GenerateContent(ctx, prompt, imgPart)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": fmt.Sprintf("AI processing failed: %v", err)})
	}

	return c.JSON(fiber.Map{
		"message": "Extracted successfully",
		"data":    resp.Candidates[0].Content.Parts[0],
	})
}

// TranscribeDiary handles audio to text for daily diaries
func TranscribeDiary(c *fiber.Ctx) error {
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		return c.Status(500).JSON(fiber.Map{"error": "Gemini API key is not configured"})
	}

	file, err := c.FormFile("audio")
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Audio file is required"})
	}

	f, err := file.Open()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to open audio file"})
	}
	defer f.Close()

	audioData, err := io.ReadAll(f)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to read audio data"})
	}

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to initialize AI client"})
	}
	defer client.Close()

	reader := bytes.NewReader(audioData)
	uploadedFile, err := client.UploadFile(ctx, "", reader, nil)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": fmt.Sprintf("Failed to upload audio: %v", err)})
	}

	model := client.GenerativeModel("gemini-1.5-flash")
	prompt := genai.Text("Transcribe this audio file verbatim. Return only the transcribed text.")

	resp, err := model.GenerateContent(ctx, prompt, genai.FileData{URI: uploadedFile.URI})
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": fmt.Sprintf("Transcription failed: %v", err)})
	}

	return c.JSON(fiber.Map{
		"message": "Transcription successful",
		"text":    resp.Candidates[0].Content.Parts[0],
	})
}

// PredictMaterialEstimation predicts material needs based on project ID
func PredictMaterialEstimation(c *fiber.Ctx) error {
	projectID := c.Params("id")
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		return c.Status(500).JSON(fiber.Map{"error": "Gemini API key is not configured"})
	}

	var project models.Project
	if err := db.DB.First(&project, projectID).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Project not found"})
	}

	var boqItems []models.BOQItem
	db.DB.Where("project_id = ?", projectID).Find(&boqItems)

	boqContext := ""
	for _, item := range boqItems {
		boqContext += fmt.Sprintf("- %s: %.2f %s at rate %.2f\n", item.Description, item.PlannedQuantity, item.Unit, item.Rate)
	}
	if boqContext == "" {
		boqContext = "No BOQ items defined yet."
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to initialize AI client"})
	}
	defer client.Close()

	model := client.GenerativeModel("gemini-1.5-flash")
	prompt := genai.Text(fmt.Sprintf(
		"Project: %s\nBudget: %.2f\n\nBOQ Items:\n%s\n\nBased on this project data, estimate the material requirements (cement, steel, sand) for the next 7 days. Return the response in JSON format.",
		project.Name, project.Budget, boqContext,
	))

	resp, err := model.GenerateContent(ctx, prompt)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": fmt.Sprintf("AI estimation failed: %v", err)})
	}

	return c.JSON(fiber.Map{
		"message": "Estimation complete",
		"data":    resp.Candidates[0].Content.Parts[0],
	})
}

// Chatbot handles RAG AI Copilot queries
func Chatbot(c *fiber.Ctx) error {
	var body struct {
		Prompt    string `json:"prompt"`
		ProjectID uint   `json:"project_id"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		return c.Status(500).JSON(fiber.Map{"error": "Gemini API key is not configured"})
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to initialize AI client"})
	}
	defer client.Close()

	model := client.GenerativeModel("gemini-1.5-flash")

	var project models.Project
	projectCtx := ""
	if err := db.DB.First(&project, body.ProjectID).Error; err == nil {
		var boqCount int64
		db.DB.Model(&models.BOQItem{}).Where("project_id = ?", body.ProjectID).Count(&boqCount)

		var diaryCount int64
		db.DB.Model(&models.DailyDiaryEntry{}).Where("project_id = ?", body.ProjectID).Count(&diaryCount)

		projectCtx = fmt.Sprintf(
			"Project: %s\nStatus: %s\nBudget: %.2f\nBOQ Items: %d\nDiary Entries: %d\n",
			project.Name, project.Status, project.Budget, boqCount, diaryCount,
		)
	}

	systemPrompt := fmt.Sprintf("You are an expert construction management AI Copilot for CivilOS. Here is the project context:\n%s\nAnswer the user's question succinctly and professionally.\n\nUser Question: %s", projectCtx, body.Prompt)

	prompt := genai.Text(systemPrompt)

	resp, err := model.GenerateContent(ctx, prompt)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": fmt.Sprintf("AI chatbot failed: %v", err)})
	}

	return c.JSON(fiber.Map{
		"message": "Success",
		"reply":   resp.Candidates[0].Content.Parts[0],
	})
}
