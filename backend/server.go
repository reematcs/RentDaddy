package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
)

type Item struct {
	ID    string `json:"id"`
	Value string `json:"value"`
}

var items = make(map[string]Item)

func PutItemHandler(w http.ResponseWriter, r *http.Request) {
	itemID := chi.URLParam(r, "id")

	var updatedItem Item
	if err := json.NewDecoder(r.Body).Decode(&updatedItem); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if itemID != updatedItem.ID {
		http.Error(w, "ID in path and body do not match", http.StatusBadRequest)
		return
	}

	if _, ok := items[itemID]; !ok {
		http.Error(w, "Item not found", http.StatusNotFound)
		return
	}

	items[itemID] = updatedItem

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(updatedItem)
}

func main() {
	// OS signal channel
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	r := chi.NewRouter()
	r.Use(middleware.Logger)

	r.Use(cors.Handler(cors.Options{
		AllowedOrigins: []string{"*"},
		// AllowOriginFunc:  func(r *http.Request, origin string) bool { return true },
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: false,
		MaxAge:           300, // Maximum value not ignored by any of major browsers
	}))

	r.Get("/test/get", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Success in get"))
	})

	// Sample data
	items["1"] = Item{ID: "1", Value: "initial value"}

	r.Post("/test/post", func(w http.ResponseWriter, r *http.Request) {
		// fmt.Printf("%v",items)
		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Failed to read body", http.StatusInternalServerError)
			return
		}
		defer r.Body.Close()
		fmt.Printf("%s", body)
		fmt.Printf("post success")
		w.WriteHeader(http.StatusOK)
		w.Write(body)
		w.Write([]byte("Success in post"))
	})

	r.Put("/test/put", func(w http.ResponseWriter, r *http.Request) {
		// fmt.Printf("%v",items)
		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Failed to read body", http.StatusInternalServerError)
			return
		}
		defer r.Body.Close()
		fmt.Printf("%s", body)
		fmt.Printf("put success")
		w.WriteHeader(http.StatusOK)
		w.Write(body)
		w.Write([]byte("Success in put"))
	})

	r.Delete("/test/delete", func(w http.ResponseWriter, r *http.Request) {
		// fmt.Printf("%v",items)
		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Failed to read body", http.StatusInternalServerError)
			return
		}
		defer r.Body.Close()
		fmt.Printf("%s", body)
		fmt.Printf("delete success")
		w.WriteHeader(http.StatusOK)
		w.Write(body)
	})

	r.Patch("/test/patch", func(w http.ResponseWriter, r *http.Request) {
		// fmt.Printf("%v",items)
		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Failed to read body", http.StatusInternalServerError)
			return
		}
		defer r.Body.Close()
		fmt.Printf("%s", body)
		fmt.Printf("patch success")
		w.WriteHeader(http.StatusOK)
		w.Write(body)
	})

	// Server config
	server := &http.Server{
		Addr:    ":3069",
		Handler: r,
	}

	// Start server
	go func() {
		log.Println("Server is running on port 3069....")
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("server error: %v", err)
		}
	}()

	// Block until we reveive an interrupt signal
	<-sigChan
	log.Println("shutting down server...")

	// Gracefully shutdown the server
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer shutdownCancel()
	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Fatalf("server shutdown failed: %v", err)
	}
}
