// File: main_test.go
package handlers_test

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/golang/mock/gomock"
	"github.com/stretchr/testify/assert"

	mockdb "github.com/careecodes/RentDaddy/internal/db/generated/mocks"
	"github.com/careecodes/RentDaddy/pkg/handlers"
)

// TestMain initializes the test suite
func TestMain(m *testing.M) {
	// Initialize `gomock`
	mockCtrl := gomock.NewController(nil)
	defer mockCtrl.Finish()

	// Run all tests
	m.Run()
}

// TestCreateLeaseHandler tests the CreateLease endpoint with a mocked database
func TestCreateLeaseHandler(t *testing.T) {
	mockCtrl := gomock.NewController(t)
	defer mockCtrl.Finish()

	// Mock Queries
	mockDBTX := mockdb.NewMockDBTX(mockCtrl)

	// Create a mock LeaseHandler
	handler := handlers.NewLeaseHandler(nil, mockDBTX)

	// Define test request payload
	testRequest := handlers.CreateLeaseRequest{
		LeaseVersion:    1,
		LeaseFileKey:    "s3://bucket/path/to/lease.pdf",
		LeaseTemplateID: 101,
		TenantID:        1,
		LandlordID:      2,
		ApartmentID:     10,
		LeaseStartDate:  time.Now(),
		LeaseEndDate:    time.Now().AddDate(1, 0, 0),
		RentAmount:      1500.00,
		LeaseStatus:     "pending",
		CreatedBy:       1,
		UpdatedBy:       1,
	}

	// Mock database response for lease creation
	mockDBTX.EXPECT().
		CreateLease(gomock.Any(), gomock.Any()).
		Return(int64(123), nil) // Simulate lease ID 123 created

	// Convert request to JSON
	reqBody, err := json.Marshal(testRequest)
	assert.NoError(t, err, "Failed to marshal request")

	// Create a test HTTP request
	req, err := http.NewRequest("POST", "/leases", bytes.NewBuffer(reqBody))
	assert.NoError(t, err, "Failed to create request")
	req.Header.Set("Content-Type", "application/json")

	// Record response
	rr := httptest.NewRecorder()

	// Call handler function
	handler.CreateLease(rr, req)

	// Assert response status
	assert.Equal(t, http.StatusCreated, rr.Code, "Expected HTTP 201 Created")

	// Parse response JSON
	var response map[string]interface{}
	err = json.Unmarshal(rr.Body.Bytes(), &response)
	assert.NoError(t, err, "Failed to parse response JSON")

	// Check expected values
	assert.Equal(t, "Lease created successfully", response["message"], "Response message should match")
	assert.Equal(t, float64(123), response["lease_id"], "Lease ID should match mock response")
}

// TestCreateLeaseHandler_DBError tests CreateLease when the database fails
func TestCreateLeaseHandler_DBError(t *testing.T) {
	mockCtrl := gomock.NewController(t)
	defer mockCtrl.Finish()

	mockDBTX := mockdb.NewMockDBTX(mockCtrl)

	handler := handlers.LeaseHandler{
		queries: mockDBTX,
	}

	testRequest := handlers.CreateLeaseRequest{
		LeaseVersion:    1,
		LeaseFileKey:    "s3://bucket/path/to/lease.pdf",
		LeaseTemplateID: 101,
		TenantID:        1,
		LandlordID:      2,
		ApartmentID:     10,
		LeaseStartDate:  time.Now(),
		LeaseEndDate:    time.Now().AddDate(1, 0, 0),
		RentAmount:      1500.00,
		LeaseStatus:     "pending",
		CreatedBy:       1,
		UpdatedBy:       1,
	}

	// Simulate database failure
	mockDBTX.EXPECT().
		CreateLease(gomock.Any(), gomock.Any()).
		Return(int64(0), errors.New("database error"))

	reqBody, err := json.Marshal(testRequest)
	assert.NoError(t, err)

	req, err := http.NewRequest("POST", "/leases", bytes.NewBuffer(reqBody))
	assert.NoError(t, err)
	req.Header.Set("Content-Type", "application/json")

	rr := httptest.NewRecorder()
	handler.CreateLease(rr, req)

	assert.Equal(t, http.StatusInternalServerError, rr.Code)
	assert.Contains(t, rr.Body.String(), "Failed to create lease")
}
