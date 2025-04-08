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
	"strings"
	"time"
)

// DocumensoSetupRequest represents the request format for setting up a Documenso admin
type DocumensoSetupRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
	Name     string `json:"name"`
}

// AdminConfig holds configuration information generated from admin signup
type AdminConfig struct {
	AdminEmail    string `json:"adminEmail"`
	WebhookSecret string `json:"webhookSecret"`
	APIToken      string `json:"apiToken"`
}

// AutomateDocumensoSignup handles the request to set up a Documenso admin account
func AutomateDocumensoSignup(w http.ResponseWriter, r *http.Request) {
	log.Println("[DOCUMENSO_SETUP] Starting Documenso admin account setup")

	// Parse the request body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		log.Printf("[DOCUMENSO_SETUP] Error reading request body: %v", err)
		http.Error(w, "Error reading request body", http.StatusBadRequest)
		return
	}

	var setupReq DocumensoSetupRequest
	if err := json.Unmarshal(body, &setupReq); err != nil {
		log.Printf("[DOCUMENSO_SETUP] Error parsing request JSON: %v", err)
		http.Error(w, "Error parsing request", http.StatusBadRequest)
		return
	}

	// Validate the request
	if setupReq.Email == "" || setupReq.Password == "" || setupReq.Name == "" {
		log.Println("[DOCUMENSO_SETUP] Missing required fields in request")
		http.Error(w, "Email, password, and name are required", http.StatusBadRequest)
		return
	}

	// Get the Documenso URL from environment or use default
	documensoURL := os.Getenv("DOCUMENSO_PUBLIC_URL")
	if documensoURL == "" {
		documensoURL = "https://docs.curiousdev.net"
	}

	// Determine the path to the script
	scriptDir := os.Getenv("SCRIPT_DIR")
	if scriptDir == "" {
		// Default to the same directory as this file in production
		scriptDir = "/app/pkg/handlers/documenso"
	}
	scriptPath := filepath.Join(scriptDir, "documenso_signup.js")

	// Check if the script exists
	if _, err := os.Stat(scriptPath); os.IsNotExist(err) {
		log.Printf("[DOCUMENSO_SETUP] Script not found at %s", scriptPath)
		http.Error(w, "Setup script not found", http.StatusInternalServerError)
		return
	}

	// Create temporary directory for screenshots if needed
	screenshotDir := "/tmp/documenso-screenshots"
	if err := os.MkdirAll(screenshotDir, 0755); err != nil {
		log.Printf("[DOCUMENSO_SETUP] Error creating screenshot directory: %v", err)
	}

	// Set up environment for the script
	env := []string{
		fmt.Sprintf("DOCUMENSO_URL=%s", documensoURL),
		fmt.Sprintf("ADMIN_EMAIL=%s", setupReq.Email),
		fmt.Sprintf("ADMIN_PASSWORD=%s", setupReq.Password),
		fmt.Sprintf("ADMIN_NAME=%s", setupReq.Name),
		fmt.Sprintf("SCREENSHOT_DIR=%s", screenshotDir),
		"PATH=" + os.Getenv("PATH"),
		"NODE_PATH=" + os.Getenv("NODE_PATH"),
	}

	// Run the script with a timeout
	log.Printf("[DOCUMENSO_SETUP] Running signup script for %s", setupReq.Email)

	cmd := exec.Command("node", scriptPath)
	cmd.Env = env

	// Capture stdout and stderr
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("[DOCUMENSO_SETUP] Error running script: %v\nOutput: %s", err, string(output))
		http.Error(w, "Error running signup script", http.StatusInternalServerError)
		return
	}

	log.Printf("[DOCUMENSO_SETUP] Script output: %s", string(output))

	// Check for config file created by the script
	configFilePath := "/tmp/documenso_config.json"
	configData := make(map[string]AdminConfig)

	// Try to read the config file, with a short retry loop
	var configFile []byte
	maxRetries := 5
	for i := 0; i < maxRetries; i++ {
		configFile, err = os.ReadFile(configFilePath)
		if err == nil {
			break
		}
		log.Printf("[DOCUMENSO_SETUP] Config file not found yet, retry %d/%d: %v", i+1, maxRetries, err)
		time.Sleep(1 * time.Second)
	}

	if err != nil {
		log.Printf("[DOCUMENSO_SETUP] Failed to read config file after retries: %v", err)
		// Continue anyway, as the account might have been created successfully
	} else {
		// Parse the config file
		if err := json.Unmarshal(configFile, &configData); err != nil {
			log.Printf("[DOCUMENSO_SETUP] Error parsing config file: %v", err)
			// Continue anyway
		} else {
			config := configData["documenso"]
			log.Printf("[DOCUMENSO_SETUP] Successfully extracted config: admin=%s, webhook created=%v, API token created=%v",
				config.AdminEmail,
				config.WebhookSecret != "",
				config.APIToken != "")

			// Update environment variables with the new values
			if config.WebhookSecret != "" {
				os.Setenv("DOCUMENSO_WEBHOOK_SECRET", config.WebhookSecret)
				log.Printf("[DOCUMENSO_SETUP] Updated DOCUMENSO_WEBHOOK_SECRET environment variable")
			}

			if config.APIToken != "" {
				os.Setenv("DOCUMENSO_API_KEY", config.APIToken)
				log.Printf("[DOCUMENSO_SETUP] Updated DOCUMENSO_API_KEY environment variable")
			}
		}
	}

	// Check if signup was successful by scanning the output
	success := strings.Contains(string(output), "SUCCESS") ||
		strings.Contains(string(output), "PARTIAL SUCCESS") ||
		strings.Contains(string(output), "Config written to")

	if !success {
		log.Println("[DOCUMENSO_SETUP] Signup appears to have failed based on output")
		http.Error(w, "Documenso signup failed", http.StatusInternalServerError)
		return
	}

	// Success response
	w.Header().Set("Content-Type", "application/json")
	response := map[string]interface{}{
		"success": true,
		"message": "Documenso admin account setup completed",
		"email":   setupReq.Email,
	}

	// Add config data if available
	if len(configData) > 0 {
		config := configData["documenso"]
		// Only include webhook secret and API token status (not the actual values for security)
		response["webhook_created"] = config.WebhookSecret != ""
		response["api_token_created"] = config.APIToken != ""
	}

	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("[DOCUMENSO_SETUP] Error encoding response: %v", err)
		http.Error(w, "Error encoding response", http.StatusInternalServerError)
		return
	}
	log.Println("[DOCUMENSO_SETUP] Documenso setup completed successfully")
}
