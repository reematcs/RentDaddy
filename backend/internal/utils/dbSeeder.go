package utils

import (
	"context"
	db "github.com/careecodes/RentDaddy/internal/db/generated"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"log"
	"time"
)

func SeedDB(pool *pgxpool.Pool, queries *db.Queries) {
	// Create a new test user
	user := db.CreateUserParams{
		ClerkID:   "clerk_user_id",
		Email:     "test@gmail.com",
		FirstName: "Mister",
		LastName:  "Director",
		Phone:     pgtype.Text{String: "+254712345678", Valid: true},
		Status:    db.AccountStatusActive,
		Role:      db.RoleAdmin,
		LastLogin: pgtype.Timestamp{Time: time.Now(), Valid: true},
		CreatedAt: pgtype.Timestamp{Time: time.Now(), Valid: true},
		UpdatedAt: pgtype.Timestamp{Time: time.Now(), Valid: true},
	}

	_, err := queries.CreateUser(context.Background(), user)
	if err != nil {
		log.Printf("Error seeding user: %v", err)
		log.Fatal("Failed to seed the database with initial user data")
		return
	} else {
		log.Printf("User seeded successfully: %v", user.Email)
	}

	// Create a new work order
	workOrder := db.CreateWorkOrderParams{
		CreatedBy:   1,
		OrderNumber: 1,
		Category:    db.WorkCategoryPlumbing,
		Title:       "Leaky Faucet",
		Description: "The kitchen faucet is leaking.",
		UnitNumber:  101,
		Status:      db.StatusOpen,
		UpdatedAt:   pgtype.Timestamp{Time: time.Now(), Valid: true},
		CreatedAt:   pgtype.Timestamp{Time: time.Now(), Valid: true},
	}

	_, err = queries.CreateWorkOrder(context.Background(), workOrder)
	if err != nil {
		log.Printf("Error seeding work order: %v", err)
		log.Fatal("Failed to seed the database with initial work order data")
	}
}
