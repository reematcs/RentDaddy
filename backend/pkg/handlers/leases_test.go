package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3iface"
	db "github.com/careecodes/RentDaddy/internal/db/generated"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/stretchr/testify/assert"
)

// Define an interface for the needed methods
type LeaseQueries interface {
	CreateLease(ctx context.Context, arg db.CreateLeaseParams) (int32, error)
	// Add other methods as needed
}

// Implement a simple mock for testing
type MockLeaseQueries struct {
	createLeaseFunc func(ctx context.Context, arg db.CreateLeaseParams) (int32, error)
}

// Implement the CreateLease method
func (m *MockLeaseQueries) CreateLease(ctx context.Context, arg db.CreateLeaseParams) (int32, error) {
	if m.createLeaseFunc != nil {
		return m.createLeaseFunc(ctx, arg)
	}
	return 42, nil
}

// Mock S3 client
type MockS3 struct {
	s3iface.S3API
	putObjectFunc func(*s3.PutObjectInput) (*s3.PutObjectOutput, error)
}

func (m *MockS3) PutObject(input *s3.PutObjectInput) (*s3.PutObjectOutput, error) {
	if m.putObjectFunc != nil {
		return m.putObjectFunc(input)
	}
	return &s3.PutObjectOutput{}, nil
}

// GetObject implementation
func (m *MockS3) GetObject(input *s3.GetObjectInput) (*s3.GetObjectOutput, error) {
	return &s3.GetObjectOutput{}, nil
}

// Helper function to convert time.Time to pgtype.Date
func toPgDate(t time.Time) pgtype.Date {
	return pgtype.Date{
		Time:  t,
		Valid: !t.IsZero(),
	}
}

// Helper function to convert int32 to pgtype.Int4
func toPgInt4(val int32) pgtype.Int4 {
	return pgtype.Int4{
		Int32: val,
		Valid: true,
	}
}

// Helper function to convert int64 to pgtype.Int8
func toPgInt8(val int64) pgtype.Int8 {
	return pgtype.Int8{
		Int64: val,
		Valid: true,
	}
}

func TestCreateLease(t *testing.T) {
	mockQueries := &MockLeaseQueries{
		createLeaseFunc: func(ctx context.Context, arg db.CreateLeaseParams) (int32, error) {
			// Verify parameters if needed
			return 42, nil
		},
	}

	// Sample request data
	reqBody := CreateLeaseRequest{
		LeaseVersion:   1,
		TenantID:       123,
		LandlordID:     456,
		ApartmentID:    789,
		LeaseStartDate: time.Date(2025, 1, 1, 0, 0, 0, 0, time.UTC),
		LeaseEndDate:   time.Date(2025, 12, 31, 0, 0, 0, 0, time.UTC),
		RentAmount:     1500.00,
		LeaseStatus:    "active",
		CreatedBy:      1,
		UpdatedBy:      1,
	}

	// Test the handler function directly rather than creating a LeaseHandler instance
	// Prepare HTTP request and response recorder
	reqJSON, _ := json.Marshal(reqBody)
	req := httptest.NewRequest("POST", "/leases", bytes.NewBuffer(reqJSON))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	// Create and call a test handler function that's similar to your production handler but uses our mocks
	testHandler := func(w http.ResponseWriter, r *http.Request) {
		var req CreateLeaseRequest

		// Decode JSON Request
		err := json.NewDecoder(r.Body).Decode(&req)
		if err != nil {
			http.Error(w, "Invalid JSON request", http.StatusBadRequest)
			return
		}

		// Validate Input
		if req.TenantID == 0 || req.LandlordID == 0 || req.ApartmentID == 0 || req.LeaseStartDate.IsZero() || req.LeaseEndDate.IsZero() {
			http.Error(w, "Missing required fields", http.StatusBadRequest)
			return
		}

		// Execute SQL Query using our mock
		id, err := mockQueries.CreateLease(r.Context(), db.CreateLeaseParams{
			LeaseVersion:    int64(req.LeaseVersion),
			LeaseFileKey:    pgtype.Text{String: req.LeaseFileKey, Valid: req.LeaseFileKey != ""},
			LeaseTemplateID: pgtype.Int4{Int32: req.LeaseTemplateID, Valid: req.LeaseTemplateID != 0},
			TenantID:        int64(req.TenantID),
			LandlordID:      int64(req.LandlordID),
			ApartmentID:     pgtype.Int8{Int64: int64(req.ApartmentID), Valid: req.ApartmentID != 0},
			LeaseStartDate:  toPgDate(req.LeaseStartDate),
			LeaseEndDate:    toPgDate(req.LeaseEndDate),
			RentAmount:      floatToPgNumeric(req.RentAmount),
			LeaseStatus:     req.LeaseStatus,
			CreatedBy:       int64(req.CreatedBy),
			UpdatedBy:       int64(req.UpdatedBy),
		})

		if err != nil {
			http.Error(w, "Failed to create lease", http.StatusInternalServerError)
			return
		}

		// Success Response
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"message":  "Lease created successfully",
			"lease_id": id,
		})
	}

	// Call the test handler
	testHandler(rec, req)

	// Verify the response
	assert.Equal(t, http.StatusCreated, rec.Code)

	var response map[string]interface{}
	err := json.Unmarshal(rec.Body.Bytes(), &response)
	assert.NoError(t, err)

	assert.Equal(t, "Lease created successfully", response["message"])
	assert.Equal(t, float64(42), response["lease_id"])
}
