-- name: CreateLease :one
INSERT INTO lease (document_id, user_id, status, start_time, end_time)
VALUES ($1, $2, 'active', $3, $4)
RETURNING *;

-- name: RenewLease :one
UPDATE lease
SET end_time = $1, updated_at = now()
WHERE id = $2 AND status = 'active'
RETURNING *;

-- name: TerminateLease :one
UPDATE lease
SET status = 'terminated', updated_at = now()
WHERE id = $1
RETURNING *;

-- name: ListLeases :many
SELECT * FROM lease ORDER BY created_at DESC;

-- name: GetLease :one
SELECT * FROM lease WHERE id = $1 LIMIT 1;

-- name: UpdateLease :one
UPDATE lease
SET document_id = $1,
    user_id = $2,
    status = $3,
    start_time = $4,
    end_time = $5,
    updated_at = now()
WHERE id = $6
RETURNING *;
