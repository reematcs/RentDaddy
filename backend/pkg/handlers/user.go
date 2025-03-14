package handlers

import (
	"encoding/json"
	"io"
	"log"
	"net/http"
	"strconv"

	db "github.com/careecodes/RentDaddy/internal/db/generated"
	"github.com/go-chi/chi/v5"
)

func GetTenantByClerkId(w http.ResponseWriter, r *http.Request, queries *db.Queries) {
	userClerkId := r.URL.Query().Get("clerk_id")

	res, err := queries.GetTenantByClerkID(r.Context(), userClerkId)
	if err != nil {
		log.Printf("[USER_HANDLER] Get tenant by ClerkId failed: %v", err)
		http.Error(w, "Faild querying user data", http.StatusInternalServerError)
		return
	}

	jsonRes, err := json.Marshal(res)
	if err != nil {
		log.Printf("[USER_HANDLER] Failed converting JSON: %v", err)
		http.Error(w, "Faild converting JSON", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(jsonRes))
	w.WriteHeader(200)
}

func GetAllUsers(w http.ResponseWriter, r *http.Request, queries *db.Queries, typeOfUser db.Role) {
	limitStr := r.URL.Query().Get("limit")
	offsetStr := r.URL.Query().Get("offset")

	limit := 20
	if limitStr != "" {
		parsedLimit, err := strconv.Atoi(limitStr)
		if err == nil {
			limit = parsedLimit
		} else {
			log.Printf("[USER_HANDLER] Inavlid Limit value: %v", err)
		}
	}

	offset := 0
	if offsetStr != "" {
		parsedOffset, err := strconv.Atoi(offsetStr)
		if err == nil {
			offset = parsedOffset
		} else {
			log.Printf("[USER_HANDLER] Inavlid offset value: %v", err)
		}
	}

	res, err := queries.GetUsers(r.Context(), db.GetUsersParams{
		Role:   typeOfUser,
		Limit:  int32(limit),
		Offset: int32(offset),
	})
	if err != nil {
		log.Printf("[USER_HANDLER] Failed getting tenants: %v", err)
		http.Error(w, "Failed getting tenants", http.StatusInternalServerError)
		return

	}

	jsonRes, err := json.Marshal(res)
	if err != nil {
		log.Printf("[USER_HANDLER] Failed parsing tenants to JSON: %v", err)
		http.Error(w, "Failed parsing to JSON", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(jsonRes))
	w.WriteHeader(200)
}

func UpdateTenantCredentials(w http.ResponseWriter, r *http.Request, queries *db.Queries) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		log.Printf("[USER_HANDLER] Failed reading request body: %v", err)
		http.Error(w, "Error reading request body", http.StatusInternalServerError)
		return
	}

	var updatePayload db.UpdateUserCredentialsParams
	err = json.Unmarshal(body, &updatePayload)
	if err != nil {
		log.Printf("[USER_HANDLER] Failed parsing payload to JSON: %v", err)
		http.Error(w, "Error parsing payload to JSON", http.StatusInternalServerError)
		return
	}

	err = queries.UpdateUserCredentials(r.Context(), updatePayload)
	if err != nil {
		log.Printf("[USER_HANDLER] Failed updating user credentials: %v", err)
		http.Error(w, "Error updating user credentials", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(200)
}

func GetAdminByClerkId(w http.ResponseWriter, r *http.Request, queries *db.Queries) {
	userClerkId := chi.URLParam(r, "clerk_id")

	res, err := queries.GetAdminByClerkID(r.Context(), userClerkId)
	if err != nil {
		log.Printf("[USER_HANDLER] Error Get admin by clerk_id failed: %v", err)
		http.Error(w, "Error querying user data", http.StatusInternalServerError)
		return
	}

	jsonRes, err := json.Marshal(res)
	if err != nil {
		log.Printf("[USER_HANDLER] Failed converting JSON: %v", err)
		http.Error(w, "Error converting JSON", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(jsonRes))
	w.WriteHeader(200)
}

// func UpdateTenantProfile(w http.ResponseWriter, r *http.Request, pool *pgxpool.Pool, quries *db.Queries) {
// 	userClerkId := r.URL.Query().Get("clerk_id")
//
// 	tx, err := pool.BeginTx(r.Context(), pgx.TxOptions{})
// 	if err != nil {
// 		log.Printf("[USER_HANDLER] Error DB transaction failed: %v", err)
// 		http.Error(w, "DB error", http.StatusInternalServerError)
// 		return
// 	}
// }
