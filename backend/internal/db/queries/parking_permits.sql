-- name: CreateParkingPermit :one
INSERT INTO parking_permits (
    id,
    user_id,
    created_at, 
    updated_at, 
    expires_at
)
VALUES (
    $1,
    $2,
    $3,
    $4,
    $5
)
RETURNING *;

-- name: GetParkingPermit :one
SELECT id, user_id, created_at, updated_at, expires_at
FROM parking_permits
WHERE id = $1
LIMIT 1;

-- name: GetParkingPermits :many
SELECT *
FROM parking_permits
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: DeleteParkingPermit :exec
DELETE FROM parking_permits
WHERE id = $1;