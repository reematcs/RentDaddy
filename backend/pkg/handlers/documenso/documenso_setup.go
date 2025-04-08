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

	// MANUAL SETUP INSTRUCTIONS MESSAGE
	log.Println("[DOCUMENSO_SETUP] Automated setup has been removed. Please set up Documenso manually:")
	log.Println("[DOCUMENSO_SETUP] 1. Go to " + documensoURL + "/signup and create an account with:")
	log.Println("[DOCUMENSO_SETUP]    - Email: " + setupReq.Email)
	log.Println("[DOCUMENSO_SETUP]    - Name: " + setupReq.Name)
	log.Println("[DOCUMENSO_SETUP] 2. Go to Settings -> API Tokens to create an API token")
	log.Println("[DOCUMENSO_SETUP] 3. Go to Settings -> Webhooks to set up the webhook")
	log.Println("[DOCUMENSO_SETUP] 4. Add the API token and webhook secret to your environment")

	// Success response
	w.Header().Set("Content-Type", "application/json")
	response := map[string]interface{}{
		"success": false,
		"message": "Automated setup has been removed. Please follow the instructions in the logs to set up Documenso manually.",
		"email":   setupReq.Email,
		"manual_instructions": []string{
			"1. Go to " + documensoURL + "/signup and create an account",
			"2. Go to Settings -> API Tokens to create an API token",
			"3. Go to Settings -> Webhooks to set up the webhook",
			"4. Add the API token and webhook secret to your environment",
		},
	}

	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("[DOCUMENSO_SETUP] Error encoding response: %v", err)
		http.Error(w, "Error encoding response", http.StatusInternalServerError)
		return
	}
	log.Println("[DOCUMENSO_SETUP] Manual Documenso setup instructions provided")
}
