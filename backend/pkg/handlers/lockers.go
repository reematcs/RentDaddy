package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	db "github.com/careecodes/RentDaddy/internal/db/generated"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgtype" // Updated import path
)

func GetLockersHandler(w http.ResponseWriter, r *http.Request, queries *db.Queries, limit, offset int32) {
    lockers, err := queries.GetLockers(r.Context(), db.GetLockersParams{
        Limit:  limit,
        Offset: offset,
    })
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    json.NewEncoder(w).Encode(lockers)
}

func GetLockerHandler(w http.ResponseWriter, r *http.Request, queries *db.Queries) {
	// id needs to be a string because chi.URLParam returns a string?
    idStr := chi.URLParam(r, "id")
    id, err := strconv.ParseInt(idStr, 10, 64)
    if err != nil {
        http.Error(w, "Invalid locker ID", http.StatusBadRequest)
        return
    }
    locker, err := queries.GetLocker(r.Context(), id)
    if err != nil {
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }
    json.NewEncoder(w).Encode(locker)
}

func UpdateLockerUserHandler(w http.ResponseWriter, r *http.Request, queries *db.Queries) {
    // Convert string ID to int64
    idStr := chi.URLParam(r, "id")
    id, err := strconv.ParseInt(idStr, 10, 64)
    if err != nil {
        http.Error(w, "Invalid locker ID", http.StatusBadRequest)
        return
    }
    
    // Define request structure
    var req struct {
        UserID *int64 `json:"user_id"`
        InUse  bool   `json:"in_use"`
    }

    // Decode request body
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    // Create pgtype.Int8 value
    var userID pgtype.Int8
    if req.UserID == nil {
        userID = pgtype.Int8{Valid: false}
    } else {
        userID = pgtype.Int8{Int64: *req.UserID, Valid: true}
    }

    // Update locker user and status
    err = queries.UpdateLockerUser(r.Context(), db.UpdateLockerUserParams{
        ID:     id,
        UserID: userID,
        InUse:  req.InUse,
    })
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    w.WriteHeader(http.StatusOK)
}

func UpdateLockerAccessCodeHandler(w http.ResponseWriter, r *http.Request, queries *db.Queries) {
    idStr := chi.URLParam(r, "id")
    id, err := strconv.ParseInt(idStr, 10, 64)
    if err != nil {
        http.Error(w, "Invalid locker ID", http.StatusBadRequest)
        return
    }
    var req struct {
        AccessCode string `json:"access_code"`
    }
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    err = queries.UpdateAccessCode(r.Context(), db.UpdateAccessCodeParams{
        ID:         id,
        AccessCode: pgtype.Text{String: req.AccessCode, Valid: true},
    })
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    w.WriteHeader(http.StatusOK)
}