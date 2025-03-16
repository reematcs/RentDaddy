package handlers

import (
	"encoding/json"
	"log"
	"math/big"
	"net/http"
	"time"

	"bytes"
	"fmt"

	"os"

	db "github.com/careecodes/RentDaddy/internal/db/generated"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

// TODO: Redirect to local container
var DOCUMENSO_API_KEY = os.Getenv("DOCUMENSO_API_KEY") // Fetch from environment variables
var DOCUMENSO_API_URL = os.Getenv("DOCUMENSO_API_URL")

// LeaseHandler encapsulates dependencies for lease-related handlers
type LeaseHandler struct {
	pool    *pgxpool.Pool
	queries *db.Queries
}

// NewLeaseHandler initializes a LeaseHandler
func NewLeaseHandler(pool *pgxpool.Pool, queries *db.Queries) *LeaseHandler {
	return &LeaseHandler{
		pool:    pool,
		queries: queries,
	}
}

// Convert float64 to pgtype.Numeric
func floatToPgNumeric(value float64) pgtype.Numeric {
	bigFloat := big.NewFloat(value)
	bigInt, accuracy := bigFloat.Int(nil)
	exp := int32(0)
	if accuracy != big.Exact {
		exp = -2 // Adjust precision if necessary
	}

	return pgtype.Numeric{
		Int:   bigInt,
		Exp:   exp,
		Valid: true,
	}
}

// reconcile CreateLeaseRequest and CreateLeaseResponse with db/generated/models Lease struct
type CreateLeaseRequest struct {
	db.Lease `json:",inline"` // Embedding Lease struct to inherit fields

	// Overriding fields that we want to expose with simplified types
	StartDate     time.Time `json:"start_date"`
	EndDate       time.Time `json:"end_date"`
	RentAmount    float64   `json:"rent_amount"`
	DocumentTitle string    `json:"document_title"`
}

// Convert `CreateLeaseRequest` to `db.CreateLeaseParams`
func (r CreateLeaseRequest) ToCreateLeaseParams() db.CreateLeaseParams {
	return db.CreateLeaseParams{
		LeaseNumber:    0, // Auto-generated
		ExternalDocID:  "",
		TenantID:       r.TenantID,
		LandlordID:     r.LandlordID,
		ApartmentID:    pgtype.Int8{Int64: 0, Valid: false}, // Default empty
		LeaseStartDate: pgtype.Date{Time: r.StartDate, Valid: true},
		LeaseEndDate:   pgtype.Date{Time: r.EndDate, Valid: true},
		RentAmount:     floatToPgNumeric(r.RentAmount),
		LeaseStatus:    "active",
		CreatedBy:      r.CreatedBy,
		UpdatedBy:      r.CreatedBy,
	}
}

type CreateLeaseResponse struct {
	db.Lease `json:",inline"`

	// Explicitly expose only required fields
	LeaseID       int64  `json:"lease_id"`
	ExternalDocID string `json:"external_doc_id,omitempty"`
	LeaseStatus   string `json:"lease_status"`
}

type DocumensoCreateRequest struct {
	Title      string      `json:"title"`
	ExternalID string      `json:"externalId"`
	Visibility string      `json:"visibility"`
	Recipients []Recipient `json:"recipients"`
}

type Recipient struct {
	Email string `json:"email"`
	Name  string `json:"name"`
	Role  string `json:"role"`
}

type DocumensoCreateResponse struct {
	Document struct {
		ID         int64  `json:"id"`
		ExternalID string `json:"externalId"`
		Title      string `json:"title"`
	} `json:"document"`
}

// Convert `db.Lease` to `CreateLeaseResponse`
func NewCreateLeaseResponse(lease db.Lease) CreateLeaseResponse {
	return CreateLeaseResponse{
		Lease:         lease,
		LeaseID:       lease.ID,
		ExternalDocID: lease.ExternalDocID,
		LeaseStatus:   string(lease.LeaseStatus),
	}
}

func (h LeaseHandler) GetLeaseTemplates(w http.ResponseWriter, r *http.Request) {
	log.Println("Fetching lease templates from Documenso API...")
	//TODO - do console log

	// req, err := http.NewRequest("GET", DOCUMENSO_API_URL+"/api/v1/templates", nil)
	// if err != nil {
	// 	h.respondWithError(w, http.StatusInternalServerError, "Failed to create request")
	// 	return
	// }
	// req.Header.Set("Authorization", "Bearer "+DOCUMENSO_API_KEY)

	// client := &http.Client{}
	// resp, err := client.Do(req)
	// if err != nil {
	// 	h.respondWithError(w, http.StatusInternalServerError, "Failed to fetch templates")
	// 	return
	// }
	// defer resp.Body.Close()

	// if resp.StatusCode != http.StatusOK {
	// 	h.respondWithError(w, http.StatusInternalServerError, "Error fetching templates from Documenso")
	// 	return
	// }

	//var templatesResponse interface{}
	// if err := json.NewDecoder(resp.Body).Decode(&templatesResponse); err != nil {
	// 	h.respondWithError(w, http.StatusInternalServerError, "Failed to parse response")
	// 	return
	// }
	// if err := json.NewDecoder(resp.Body).Decode(&templatesResponse); err != nil {
	// 	h.respondWithError(w, http.StatusInternalServerError, "Failed to parse response")
	// 	return
	// }
	log.Println("Fetching lease templates from backend...") // ✅ Log on backend

	// ✅ Dummy response for testing
	response := map[string]interface{}{
		"status":  "success",
		"message": "Templates retrieved successfully (dummy data)",
		"data": []map[string]string{
			{"id": "1", "title": "Standard Lease Agreement"},
			{"id": "2", "title": "Short-Term Lease Agreement"},
		},
	}

	h.respondWithJSON(w, http.StatusOK, response)
}

// Utility functions for response handling
func (h LeaseHandler) respondWithError(w http.ResponseWriter, code int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	if err := json.NewEncoder(w).Encode(map[string]string{"error": message}); err != nil {
		log.Printf("[LEASE_HANDLER] Failed to encode response: %v", err)
		http.Error(w, `{"error": "Failed to encode response"}`, http.StatusInternalServerError)
	}
}

func (h LeaseHandler) respondWithJSON(w http.ResponseWriter, code int, payload interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	if err := json.NewEncoder(w).Encode(payload); err != nil {
		log.Printf("[LEASE_HANDLER] Failed to encode response: %v", err)
		http.Error(w, `{"error": "Failed to encode response"}`, http.StatusInternalServerError)
	}

}

func (h LeaseHandler) CreateLease(w http.ResponseWriter, r *http.Request) {
	var req struct {
		TemplateID  string    `json:"template_id"`
		TenantEmail string    `json:"tenant_email"`
		TenantName  string    `json:"tenant_name"`
		StartDate   time.Time `json:"start_date"`
		EndDate     time.Time `json:"end_date"`
		RentAmount  float64   `json:"rent_amount"`
		CreatedBy   int64     `json:"created_by"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondWithError(w, http.StatusBadRequest, "Invalid request")
		return
	}

	// Validate required fields
	if req.TemplateID == "" || req.TenantEmail == "" || req.TenantName == "" || req.StartDate.IsZero() || req.EndDate.IsZero() || req.RentAmount <= 0 || req.CreatedBy == 0 {
		h.respondWithError(w, http.StatusBadRequest, "Missing or invalid fields")
		return
	}

	// Create a lease document from the template
	docCreateURL := fmt.Sprintf("%s/api/v1/templates/%s/create-document", DOCUMENSO_API_URL, req.TemplateID)
	requestBody, _ := json.Marshal(map[string]string{
		"title": fmt.Sprintf("Lease Agreement - %s", req.TenantName),
	})

	httpReq, _ := http.NewRequest("POST", docCreateURL, bytes.NewBuffer(requestBody))
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+DOCUMENSO_API_KEY)

	client := &http.Client{}
	resp, err := client.Do(httpReq)
	if err != nil || resp.StatusCode != http.StatusOK {
		h.respondWithError(w, http.StatusInternalServerError, "Failed to create lease document in Documenso")
		return
	}
	defer resp.Body.Close()

	var docResponse map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&docResponse); err != nil {
		h.respondWithError(w, http.StatusInternalServerError, "Failed to parse Documenso response")
		return
	}

	// Extract Documenso document ID
	docID := fmt.Sprintf("%v", docResponse["document"].(map[string]interface{})["id"])

	// Insert Lease into DB with ExternalDocID from Documenso
	leaseID, err := h.queries.CreateLease(r.Context(), db.CreateLeaseParams{
		LeaseNumber:    0,
		ExternalDocID:  docID,         // Store Documenso's document ID
		TenantID:       req.CreatedBy, // Assuming the user is the tenant
		LandlordID:     1,             // Placeholder for now
		ApartmentID:    pgtype.Int8{Int64: 0, Valid: false},
		LeaseStartDate: pgtype.Date{Time: req.StartDate, Valid: true},
		LeaseEndDate:   pgtype.Date{Time: req.EndDate, Valid: true},
		RentAmount:     floatToPgNumeric(req.RentAmount),
		LeaseStatus:    "active",
		CreatedBy:      req.CreatedBy,
		UpdatedBy:      req.CreatedBy,
	})
	if err != nil {
		h.respondWithError(w, http.StatusInternalServerError, "Database insert failed")
		return
	}

	// Fetch the created lease to return a complete response
	lease, err := h.queries.GetLeaseByID(r.Context(), leaseID)
	if err != nil {
		h.respondWithError(w, http.StatusInternalServerError, "Failed to retrieve lease")
		return
	}

	h.respondWithJSON(w, http.StatusOK, NewCreateLeaseResponse(lease))
}
