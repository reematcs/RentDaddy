package handlers

import (
	"context"
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

	work_order, err := queries.GetWorkOrder(ctx, workOrderNumber)
	if err != nil {
		http.Error(w, "Work order not found", http.StatusNotFound)
		return
	}

	fmt.Fprintln(w, work_order)
}
