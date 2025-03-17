package utils

import (
	"encoding/json"
	"fmt"
	db "github.com/careecodes/RentDaddy/internal/db/generated"
	"log"
)

func UnmarshalBody(body []byte, v []db.WorkOrder) error {
	var workOrders []db.WorkOrder
	err := json.Unmarshal(body, &workOrders)
	if err != nil {
		log.Printf("Error unmarshalling body: %v", err)
		return fmt.Errorf("failed to unmarshal body: %w", err)
	}

	if len(workOrders) == 0 {
		return fmt.Errorf("no work orders found in the request body")
	}

	for _, order := range workOrders {
		fmt.Printf("Work Order: %+v\n", order)
	}

	v = workOrders

	return nil
}
