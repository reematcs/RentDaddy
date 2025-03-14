package models

import "time"

// CreateLeaseRequest is used for lease creation requests
// This struct is now shared between leases.go and leases_test.go

type CreateLeaseRequest struct {
	TenantID      int64     `json:"tenant_id"`
	LandlordID    int64     `json:"landlord_id"`
	StartDate     time.Time `json:"start_date"`
	EndDate       time.Time `json:"end_date"`
	RentAmount    float64   `json:"rent_amount"`
	DocumentTitle string    `json:"document_title"`
	CreatedBy     int64     `json:"created_by"`
}

// CreateLeaseResponse is used for lease creation responses
// This struct is now shared between leases.go and leases_test.go

type CreateLeaseResponse struct {
	LeaseID       int64  `json:"lease_id"`
	ExternalDocID string `json:"external_doc_id,omitempty"`
	DocumensoURL  string `json:"documenso_url,omitempty"`
	LeaseStatus   string `json:"lease_status"`
}
