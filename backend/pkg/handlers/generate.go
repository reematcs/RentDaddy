package handlers

//go:generate mockgen -source=../../internal/db/generated/db.go -destination=mocks/mock_db.go -package=mocks
//go:generate mockgen -source=../../internal/db/generated/leases.sql.go -destination=mocks/mock_leases.go -package=mocks
