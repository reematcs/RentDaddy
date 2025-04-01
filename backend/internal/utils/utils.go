package utils

import (
	"fmt"
	"log"
	"math/big"
	"math/rand"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
)

func GetAbsoluteUrl(path string) string {
	base := os.Getenv("DOMAIN_URL")
	if base != "" {
		// Ensure no double slash
		return fmt.Sprintf("%s%s", base, path)
	}
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	return fmt.Sprintf("http://localhost:%s%s", port, path)
}

func CreatePhoneNumber() string {
	area := rand.Intn(900) + 100
	middle := rand.Intn(900) + 100
	last := rand.Intn(10000)

	return fmt.Sprintf("%d%d%d", area, middle, last)
}

func ConvertToPgTimestamp(input string) (pgtype.Timestamp, error) {
	// Parse the input string into Go's time.Time
	parsedTime, err := time.Parse(time.RFC3339, input)
	if err != nil {
		log.Printf("Error parsing timestamp: %v", err)
		return pgtype.Timestamp{}, err
	}

	// Convert to UTC and remove timezone info
	parsedTime = parsedTime.UTC()

	// Assign it to pgtype.Timestamp
	return pgtype.Timestamp{Time: parsedTime, Valid: true}, nil
}

func ConvertToPgTypeNumeric(value int) pgtype.Numeric {
	var numeric pgtype.Numeric
	numeric.Int = big.NewInt(int64(value))
	numeric.Valid = true
	return numeric
}
