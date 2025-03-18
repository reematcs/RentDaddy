-- name: CreateLocker :exec
INSERT INTO lockers (
    access_code,
    user_id,
    in_use
) VALUES (
    $1, $2, $3
);

-- name: CreateManyLockers :execrows
INSERT INTO lockers (
    access_code,
    user_id,
    in_use
)
SELECT 
    gen_random_uuid()::text,  -- generates a random UUID for access code
    NULL::bigint,             -- default null user_id, explicitly cast to bigint
    false                     -- default not in use
FROM generate_series(1, sqlc.arg(count)::int);  -- creates n number of rows

-- name: UpdateLockerUser :exec
UPDATE lockers
SET user_id = $2, in_use = $3
WHERE id = $1;

-- name: UpdateAccessCode :exec
UPDATE lockers
SET access_code = $2
WHERE id = $1;

-- name: GetLockers :many
SELECT *
FROM lockers
ORDER BY id DESC
LIMIT $1 OFFSET $2;

-- name: GetLocker :one
SELECT *
FROM lockers
WHERE id = $1
LIMIT 1;