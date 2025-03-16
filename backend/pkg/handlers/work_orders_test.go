package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/careecodes/RentDaddy/internal/utils"
	"github.com/jackc/pgx/v5/pgtype"

	db "github.com/careecodes/RentDaddy/internal/db/generated"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/assert"
)

func TestWorkOrderHandler_ListWorkOrdersHandler(t *testing.T) {
	// Set up the database connection
	dbUrl := "postgres://appuser:apppassword@localhost:5432/appdb?sslmode=disable"
	pool, err := pgxpool.New(context.Background(), dbUrl)
	if err != nil {
		t.Fatalf("an error '%s' was not expected when creating a new pgxpool", err)
	}
	defer pool.Close()

	// Create a new WorkOrderHandler with the database connection
	queries := db.New(pool)
	utils.SeedDB(pool, queries)
	handler := NewWorkOrderHandler(pool, queries)

	hardCodedTime := time.Date(2025, time.March, 16, 23, 35, 38, 0, time.UTC)
	// Create a new work order entry in the database
	createParams := db.CreateWorkOrderParams{
		CreatedBy:   1,
		OrderNumber: 1,
		Category:    db.WorkCategoryPlumbing,
		Title:       "Fix door",
		Description: "The door is broken.",
		UnitNumber:  101,
		Status:      db.StatusOpen,
		UpdatedAt:   pgtype.Timestamp{Time: hardCodedTime, Valid: true},
		CreatedAt:   pgtype.Timestamp{Time: hardCodedTime, Valid: true},
	}
	workOrder, err := queries.CreateWorkOrder(context.Background(), createParams)
	if err != nil {
		t.Fatalf("an error '%s' was not expected when creating a new work order", err)
	}

	// Create a new HTTP recorder
	req, err := http.NewRequest("GET", "/work_orders", nil)
	if err != nil {
		t.Fatalf("an error '%s' was not expected when creating a new HTTP request", err)
	}
	rr := httptest.NewRecorder()

	r := chi.NewRouter()
	r.Get("/work_orders", handler.ListWorkOrdersHandler)
	r.ServeHTTP(rr, req)

	// Check the status code
	assert.Equal(t, http.StatusOK, rr.Code)

	// Check the response body
	var workOrders []db.WorkOrder
	err = json.Unmarshal(rr.Body.Bytes(), &workOrders)
	if err != nil {
		t.Logf("Response body: %s", rr.Body.String())
		t.Fatalf("an error '%s' was not expected when unmarshalling the response body", err)
		return
	}

	// Find the created work order in the response
	var foundWorkOrder *db.WorkOrder
	for _, wo := range workOrders {
		if wo.ID == workOrder.ID {
			foundWorkOrder = &wo
			break
		}
	}

	if foundWorkOrder == nil {
		t.Fatalf("created work order not found in the response")
	}

	assert.Len(t, workOrders, 1)
	assert.Equal(t, workOrder.ID, workOrders[0].ID)
	assert.Equal(t, "Fix door", workOrders[0].Title)

	// Clean up the database by deleting the created work order
	err = queries.DeleteWorkOrder(context.Background(), workOrder.ID)
	if err != nil {
		t.Fatalf("an error '%s' was not expected when deleting the work order", err)
	}
}
