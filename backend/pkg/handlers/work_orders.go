package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	db "github.com/careecodes/RentDaddy/internal/db/generated"
	"github.com/go-chi/chi/v5"
)

func GetWorkOrderHandler(w http.ResponseWriter, r *http.Request, queries *db.Queries) {
	ctx := context.Background()

	param := chi.URLParam(r, "work_order")
	workOrderNumber, err := strconv.ParseInt(param, 10, 64)
	if err != nil {
		http.Error(w, "Invalid work order number", http.StatusBadRequest)
		return
	}

	workOrder, err := queries.GetWorkOrder(ctx, workOrderNumber)
	if err != nil {
		http.Error(w, "Work order not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(workOrder)
}

func ListWorkOrdersHandler(w http.ResponseWriter, r *http.Request, queries *db.Queries) {
	ctx := context.Background()

	props := db.ListWorkOrdersParams{
		Limit:  1,
		Offset: 25,
	}
	workOrders, err := queries.ListWorkOrders(ctx, props)
	if err != nil {
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(workOrders)
}

func CreateWorkOrderHandler(w http.ResponseWriter, r *http.Request, queries *db.Queries) {
	ctx := context.Background()

	var params db.CreateWorkOrderParams
	if err := json.NewDecoder(r.Body).Decode(&params); err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	workOrder, err := queries.CreateWorkOrder(ctx, params)
	if err != nil {
		http.Error(w, "Failed to create work order", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	err = json.NewEncoder(w).Encode(workOrder)
	if err != nil {
		http.Error(w, "Failed to create work order", http.StatusInternalServerError)
		return
	}
}

func UpdateWorkOrderHandler(w http.ResponseWriter, r *http.Request, queries *db.Queries) {
	ctx := context.Background()
	param := chi.URLParam(r, "work_order")
	workOrderNumber, err := strconv.ParseInt(param, 10, 64)
	if err != nil {
		http.Error(w, "Invalid work order number", http.StatusBadRequest)
		return
	}
	workOrder, err := queries.GetWorkOrder(ctx, workOrderNumber)
	if err != nil {
		http.Error(w, "Work order not found", http.StatusNotFound)
		return
	}

	fmt.Printf("work order: %v\n", workOrder)
	w.WriteHeader(http.StatusOK)
}

func DeleteWorkOrderHandler(w http.ResponseWriter, r *http.Request, queries *db.Queries) {
	ctx := context.Background()
	param := chi.URLParam(r, "work_order")
	workOrderNumber, err := strconv.ParseInt(param, 10, 64)
	if err != nil {
		http.Error(w, "Invalid work order number", http.StatusBadRequest)
		return
	}

	err = queries.DeleteWorkOrder(ctx, workOrderNumber)
	if err != nil {
		http.Error(w, "Work order not found", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusOK)
}
