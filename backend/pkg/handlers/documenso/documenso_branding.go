package documenso

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"time"
)

// BrandingRequest represents the request format for setting up Documenso branding
type BrandingRequest struct {
	Email       string `json:"email"`
	Password    string `json:"password"`
	BrandName   string `json:"brandName"`
	BrandURL    string `json:"brandUrl"`
	BrandDetails string `json:"brandDetails"`
	LogoPath    string `json:"logoPath,omitempty"` // Optional, will use default if not provided
}

// AutomateBrandingSetup handles the request to set up custom branding in Documenso
func AutomateBrandingSetup(w http.ResponseWriter, r *http.Request) {
	log.Println("[DOCUMENSO_BRANDING] Starting Documenso branding setup")

	// Parse the request body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		log.Printf("[DOCUMENSO_BRANDING] Error reading request body: %v", err)
		http.Error(w, "Error reading request body", http.StatusBadRequest)
		return
	}

	var brandingReq BrandingRequest
	if err := json.Unmarshal(body, &brandingReq); err != nil {
		log.Printf("[DOCUMENSO_BRANDING] Error parsing request JSON: %v", err)
		http.Error(w, "Error parsing request", http.StatusBadRequest)
		return
	}

	// Validate the request
	if brandingReq.Email == "" || brandingReq.Password == "" {
		log.Println("[DOCUMENSO_BRANDING] Missing required fields in request")
		http.Error(w, "Email and password are required", http.StatusBadRequest)
		return
	}

	// Set defaults for optional fields
	if brandingReq.BrandName == "" {
		brandingReq.BrandName = "RentDaddy"
	}
	
	if brandingReq.BrandURL == "" {
		// Try to get from environment or use default
		brandingReq.BrandURL = os.Getenv("VITE_DOMAIN_URL")
		if brandingReq.BrandURL == "" {
			brandingReq.BrandURL = "https://app.curiousdev.net"
		}
	}
	
	if brandingReq.BrandDetails == "" {
		brandingReq.BrandDetails = "RentDaddy - Smart Apartment Management\nFor support: support@curiousdev.net"
	}

	// Get the Documenso URL from environment or use default
	documensoURL := os.Getenv("DOCUMENSO_PUBLIC_URL")
	if documensoURL == "" {
		documensoURL = "https://docs.curiousdev.net"
	}

	// Create a temporary directory for screenshots
	screenshotDir := "/tmp/documenso-branding-screenshots"
	if err := os.MkdirAll(screenshotDir, 0755); err != nil {
		log.Printf("[DOCUMENSO_BRANDING] Error creating screenshot directory: %v", err)
	}

	// Determine the path to the script
	scriptDir := os.Getenv("SCRIPT_DIR")
	if scriptDir == "" {
		// Default to the same directory as this file in production
		scriptDir = "/app/pkg/handlers/documenso"
	}
	scriptPath := filepath.Join(scriptDir, "documenso_branding.js")

	// Check if the script exists
	if _, err := os.Stat(scriptPath); os.IsNotExist(err) {
		log.Printf("[DOCUMENSO_BRANDING] Script not found at %s", scriptPath)
		http.Error(w, "Branding setup script not found", http.StatusInternalServerError)
		return
	}

	// Set up environment for the script
	env := []string{
		fmt.Sprintf("DOCUMENSO_URL=%s", documensoURL),
		fmt.Sprintf("ADMIN_EMAIL=%s", brandingReq.Email),
		fmt.Sprintf("ADMIN_PASSWORD=%s", brandingReq.Password),
		fmt.Sprintf("BRAND_NAME=%s", brandingReq.BrandName),
		fmt.Sprintf("BRAND_URL=%s", brandingReq.BrandURL),
		fmt.Sprintf("BRAND_DETAILS=%s", brandingReq.BrandDetails),
		fmt.Sprintf("SCREENSHOT_DIR=%s", screenshotDir),
		"PATH=" + os.Getenv("PATH"),
		"NODE_PATH=" + os.Getenv("NODE_PATH"),
	}
	
	// Add logo path if provided
	if brandingReq.LogoPath != "" {
		env = append(env, fmt.Sprintf("LOGO_PATH=%s", brandingReq.LogoPath))
	}

	// Run the script with a timeout
	log.Printf("[DOCUMENSO_BRANDING] Running branding script for %s", brandingReq.Email)

	cmd := exec.Command("node", scriptPath)
	cmd.Env = env

	// Capture stdout and stderr
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("[DOCUMENSO_BRANDING] Error running script: %v\nOutput: %s", err, string(output))
		http.Error(w, "Error running branding script", http.StatusInternalServerError)
		return
	}

	log.Printf("[DOCUMENSO_BRANDING] Script output: %s", string(output))

	// Check if branding was successful by scanning the output
	success := false
	if string(output) != "" {
		success = contains(string(output), "SUCCESS") || 
			contains(string(output), "updated successfully") ||
			contains(string(output), "branding has been set")
	}

	if !success {
		log.Println("[DOCUMENSO_BRANDING] Branding setup appears to have failed based on output")
		http.Error(w, "Documenso branding setup failed", http.StatusInternalServerError)
		return
	}

	// Success response
	w.Header().Set("Content-Type", "application/json")
	response := map[string]interface{}{
		"success": true,
		"message": "Documenso branding setup completed",
		"timestamp": time.Now().Format(time.RFC3339),
	}

	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("[DOCUMENSO_BRANDING] Error encoding response: %v", err)
		http.Error(w, "Error encoding response", http.StatusInternalServerError)
		return
	}
	
	log.Println("[DOCUMENSO_BRANDING] Documenso branding setup completed successfully")
}

// Helper function to check if a string contains a substring
func contains(s, substr string) bool {
	return len(s) >= len(substr) && s[:len(substr)] == substr
}