CREATE TYPE "Complaint_Category" AS ENUM (
    'maintenance',
    'noise',
    'security',
    'parking',
    'neighbor',
    'trash',
    'internet',
    'lease',
    'natural_disaster',
    'other'
    );
CREATE TYPE "Status" AS ENUM (
    'open',
    'in_progress',
    'resolved',
    'closed'
    );
CREATE TYPE "Type" AS ENUM (
    'lease_agreement',
    'amendment',
    'extension',
    'termination',
    'addendum'
    );
CREATE TYPE "Lease_Status" AS ENUM (
    'draft',
    'pending_approval',
    'active',
    'expired',
    'terminated',
    'renewed'
    );
CREATE TYPE "Compliance_Status" AS ENUM (
    'pending_review',
    'compliant',
    'non_compliant',
    'exempted'
    );
CREATE TYPE "Work_Category" AS ENUM (
    'plumbing',
    'electric',
    'carpentry',
    'hvac',
    'other'
    );
CREATE TABLE IF NOT EXISTS "parking_permits"
(
    "id"            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "permit_number" BIGINT                         NOT NULL,
    "created_by"    BIGINT                         NOT NULL,
    "updated_at"    TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "expires_at"    TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
);

COMMENT ON COLUMN "parking_permits"."expires_at" IS '5 days long';
CREATE TABLE IF NOT EXISTS "complaints"
(
    "id"               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "complaint_number" BIGINT                         NOT NULL,
    "created_by"       BIGINT                         NOT NULL,
    "category"         "Complaint_Category"           NOT NULL DEFAULT "Complaint_Category" 'other',
    "title"            VARCHAR                        NOT NULL,
    "description"      TEXT                           NOT NULL,
    "unit_number"      SMALLINT                       NOT NULL,
    "status"           "Status"                       NOT NULL DEFAULT "Status" 'open',
    "updated_at"       TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "created_at"       TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
);

CREATE TABLE IF NOT EXISTS "work_orders"
(
    "id"           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "created_by"   BIGINT                         NOT NULL,
    "order_number" BIGINT                         NOT NULL,
    "category"     "Work_Category"                NOT NULL,
    "title"        VARCHAR                        NOT NULL,
    "description"  TEXT                           NOT NULL,
    "unit_number"  SMALLINT                       NOT NULL,
    "status"       "Status"                       NOT NULL DEFAULT "Status" 'open',
    "updated_at"   TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "created_at"   TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
);

CREATE TYPE "Account_Status" AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE "Role" AS ENUM ('tenant', 'admin', 'landlord');
CREATE TABLE IF NOT EXISTS "users"
(
    "id"            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "clerk_id"      TEXT                           NOT NULL, -- Clerk ID's "user_2u9IV7xs5cUaYv2MsGH3pcI5hzK" cannot be converted to UUID format
    "first_name"    VARCHAR                        NOT NULL,
    "last_name"     VARCHAR                        NOT NULL,
    "email"         VARCHAR                        NOT NULL,
    "phone"         VARCHAR                        NULL,
    "unit_number"   SMALLINT                       NULL,
    "role"          "Role"                         NOT NULL DEFAULT "Role" 'tenant',
    "status"        "Account_Status"               NOT NULL DEFAULT "Account_Status" 'active',
    "last_login"    TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "updated_at"    TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "created_at"    TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
);
CREATE INDEX "user_clerk_id_index" ON "users" ("clerk_id");
CREATE INDEX "user_unit_number_index" ON "users" ("unit_number");

COMMENT ON COLUMN "users"."clerk_id" IS 'provided by Clerk';
CREATE TABLE IF NOT EXISTS "apartments"
(
    "id"               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "unit_number"      SMALLINT                       NOT NULL,
    "price"            NUMERIC(10, 2)                 NOT NULL,
    "size"             SMALLINT                       NOT NULL,
    "management_id"    BIGINT                         NOT NULL,
    "availability"     BOOLEAN                        NOT NULL DEFAULT false,
    "lease_id"         BIGINT                         NOT NULL,
    "lease_start_date" DATE                           NOT NULL,
    "lease_end_date"   DATE                           NOT NULL,
    "updated_at"       TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "created_at"       TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
);
CREATE INDEX "apartment_unit_number_index" ON "apartments" ("unit_number");

COMMENT ON COLUMN "apartments"."unit_number" IS 'describes as <building><floor><door> -> 2145';
COMMENT ON COLUMN "apartments"."unit_number" IS 'describes as <building><floor><door> -> 2145';

-- Create the leases table
CREATE TABLE leases (
    id SERIAL PRIMARY KEY,
    lease_version BIGINT NOT NULL,  -- Versioning for lease renewals
    lease_file_key TEXT,  -- S3 file storage path for signed leases
    lease_template_id INT REFERENCES lease_templates(id), -- Template used to generate this lease
    tenant_id BIGINT NOT NULL REFERENCES tenants(id),
    landlord_id BIGINT NOT NULL REFERENCES landlords(id),
    apartment_id BIGINT REFERENCES apartments(id),
    lease_start_date DATE NOT NULL,
    lease_end_date DATE NOT NULL,
    rent_amount NUMERIC NOT NULL,
    lease_status TEXT NOT NULL CHECK (lease_status IN ('active', 'renewed', 'terminated')),
    created_by BIGINT NOT NULL REFERENCES users(id),
    updated_by BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- Create the lease_templates table
CREATE TABLE lease_templates (
    id SERIAL PRIMARY KEY,
    template_name TEXT NOT NULL,    -- Name of the template (e.g., "Standard Residential Lease")
    s3_key TEXT NOT NULL UNIQUE,    -- S3 path for the template (e.g., "templates/lease_template.pdf")
    created_by INT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT now()
);

-- Indexes
CREATE INDEX "lease_lease_version_index" ON leases ("lease_version");  -- Updated from lease_number
CREATE INDEX "lease_apartment_id_index" ON leases ("apartment_id");



CREATE TABLE IF NOT EXISTS "lockers"
(
    "id"          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "access_code" varchar,
    "in_use"      BOOLEAN NOT NULL DEFAULT false,
    "user_id"     BIGINT
);

ALTER TABLE "lockers"
    ADD CONSTRAINT "user_id_foreign" FOREIGN KEY ("user_id") REFERENCES "users" ("id");
CREATE TABLE IF NOT EXISTS "apartment_tenants"
(
    "apartment_id" BIGINT NOT NULL,
    "tenant_id"    BIGINT NOT NULL,
    PRIMARY KEY ("apartment_id", "tenant_id"),
    FOREIGN KEY ("apartment_id") REFERENCES "apartments" ("id"),
    FOREIGN KEY ("tenant_id") REFERENCES "users" ("id")
);
CREATE TABLE IF NOT EXISTS "lease_tenants"
(
    "lease_id"  BIGINT NOT NULL,
    "tenant_id" BIGINT NOT NULL,
    PRIMARY KEY ("lease_id", "tenant_id"),
    FOREIGN KEY ("lease_id") REFERENCES "leases" ("id"),
    FOREIGN KEY ("tenant_id") REFERENCES "users" ("id")
);


-- Foreign Key Constraints
ALTER TABLE "parking_permits"
    ADD CONSTRAINT "parking_permit_created_by_foreign" FOREIGN KEY ("created_by") REFERENCES "users" ("id");

ALTER TABLE "apartments"
    ADD CONSTRAINT "apartment_management_id_foreign" FOREIGN KEY ("management_id") REFERENCES "users" ("id");

ALTER TABLE "leases"
    ADD CONSTRAINT "lease_created_by_foreign" FOREIGN KEY ("created_by") REFERENCES "users" ("id");

ALTER TABLE "leases"
    ADD CONSTRAINT "lease_updated_by_foreign" FOREIGN KEY ("updated_by") REFERENCES "users" ("id");

ALTER TABLE "leases"
    ADD CONSTRAINT "lease_landlord_foreign" FOREIGN KEY ("landlord_id") REFERENCES "landlords" ("id");

ALTER TABLE "leases"
    ADD CONSTRAINT "lease_apartment_id_foreign" FOREIGN KEY ("apartment_id") REFERENCES "apartments" ("id");

ALTER TABLE "leases"
    ADD CONSTRAINT "lease_template_id_foreign" FOREIGN KEY ("lease_template_id") REFERENCES "lease_templates" ("id");

ALTER TABLE "complaints"
    ADD CONSTRAINT "complaint_created_by_foreign" FOREIGN KEY ("created_by") REFERENCES "users" ("id");

ALTER TABLE "work_orders"
    ADD CONSTRAINT "workorder_created_by_foreign" FOREIGN KEY ("created_by") REFERENCES "users" ("id");

