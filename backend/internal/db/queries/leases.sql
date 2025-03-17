-- name: CreateLease :one
INSERT INTO leases (
    lease_number, external_doc_id, tenant_id, landlord_id, apartment_id, 
    lease_start_date, lease_end_date, rent_amount, lease_status
)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
RETURNING id;

-- name: RenewLease :exec
UPDATE leases
SET 
    lease_version = lease_version + 1,  
    lease_end_date = $1, 
    rent_amount = $2, 
    lease_status = 'renewed', 
    updated_by = $3, 
    updated_at = now()
WHERE id = $4
RETURNING id;

-- name: TerminateLease :exec
UPDATE leases
SET 
    lease_status = 'terminated', 
    updated_by = $1, 
    updated_at = now()
WHERE id = $2
RETURNING id;

-- name: ListLeases :many
SELECT * FROM leases ORDER BY created_at DESC;

-- name: GetLeaseByID :one
SELECT * FROM leases WHERE id = $1 LIMIT 1;

-- name: GetLatestLeaseByTenant :one
SELECT * FROM leases WHERE tenant_id = $1 ORDER BY lease_version DESC LIMIT 1;

-- name: GetLatestLeaseByApartment :one
SELECT * FROM leases WHERE apartment_id = $1 ORDER BY lease_version DESC LIMIT 1;

-- name: UpdateLease :exec
UPDATE leases
SET 
    lease_start_date = $1,
    lease_end_date = $2,
    rent_amount = $3,
    lease_status = $4,
    updated_by = $5,
    updated_at = now()
WHERE id = $6
RETURNING id;


-- name: UpdateLeaseFileKey :exec
UPDATE leases
SET lease_file_key = $1, updated_by = $2, updated_at = now()
WHERE id = $3;

-- name: GetLeaseWithTemplate :one
SELECT leases.*, lease_templates.s3_key AS template_s3_key
FROM leases
JOIN lease_templates ON leases.lease_template_id = lease_templates.id
WHERE leases.id = $1;

-- name: CreateLeaseTemplate :one
INSERT INTO lease_templates (template_name, s3_key, created_by)
VALUES ($1, $2, $3)
RETURNING id;

