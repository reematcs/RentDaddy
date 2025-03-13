package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/careecodes/RentDaddy/internal/db"
	"github.com/jackc/pgx/pgtype"
)

type CreateLeaseRequest struct {
	TenantID      int64     `json:"tenant_id"`
	LandlordID    int64     `json:"landlord_id"`
	StartDate     time.Time `json:"start_date"`
	EndDate       time.Time `json:"end_date"`
	RentAmount    float64   `json:"rent_amount"`
	DocumentTitle string    `json:"document_title"`
}

type CreateLeaseResponse struct {
	LeaseID       int64  `json:"lease_id"`
	ExternalDocID string `json:"external_doc_id"`
	DocumensoURL  string `json:"documenso_url"`
}

func CreateLeaseHandler(w http.ResponseWriter, r *http.Request) {
	var req CreateLeaseRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Get database connection

	dbConn, err := db.ConnectDB(r.Context(), "your_postgres_connection_url")
	if err != nil {
		http.Error(w, "Failed to connect to database", http.StatusInternalServerError)
		return
	}
	defer dbConn.Close()

	queries := db.New(dbConn)

	// Save lease metadata in PostgreSQL
	lease, err := queries.CreateLease(r.Context(), db.CreateLeaseParams{
		DocumentID:     0, // Temporary placeholder until Documenso returns an ID
		TenantID:       req.TenantID,
		LeaseStartDate: pgtype.Date{Time: req.StartDate, Valid: true},
		LeaseEndDate:   pgtype.Date{Time: req.EndDate, Valid: true},
	})
	if err != nil {
		http.Error(w, "Failed to create lease", http.StatusInternalServerError)
		return
	}

	// // Call Documenso API to create the document
	// externalDocID, documensoURL, err := CreateDocumensoDocument(req.DocumentTitle)
	// if err != nil {
	// 	http.Error(w, "Failed to create document in Documenso", http.StatusInternalServerError)
	// 	return
	// }

	// Update lease with external_doc_id from Documenso
	_, err = queries.UpdateLease(r.Context(), db.UpdateLeaseParams{
		DocumentID:     lease.DocumentID,
		TenantID:       req.TenantID,
		LeaseStatus:    "active",
		LeaseStartDate: pgtype.Date{Time: req.StartDate, Valid: true},
		LeaseEndDate:   pgtype.Date{Time: req.EndDate, Valid: true},
		DocumentID_2:   lease.DocumentID, // Matches WHERE condition in SQLC
	})
	if err != nil {
		http.Error(w, "Failed to update lease with Documenso ID", http.StatusInternalServerError)
		return
	}

	// Return lease data including Documenso URL
	resp := CreateLeaseResponse{
		LeaseID:       lease.DocumentID,
		ExternalDocID: externalDocID,
		DocumensoURL:  documensoURL,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
