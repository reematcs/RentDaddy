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
CREATE TABLE "parking_permits"(
    "id" BIGINT GENERATED ALWAYS AS IDENTITY,
    "permit_number" SERIAL NOT NULL,
    "created_by" BIGINT NOT NULL,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "expires_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
);
ALTER TABLE "parking_permits"
ADD PRIMARY KEY("id");
COMMENT ON COLUMN "parking_permits"."expires_at" IS '5 days long';
CREATE TABLE "complaints"(
    "id" BIGINT GENERATED ALWAYS AS IDENTITY,
    "complaint_number" SERIAL NOT NULL,
    "created_by" BIGINT NOT NULL,
    "category" Complaint_Category NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "description" TEXT NOT NULL,
    "unit_number" SMALLINT NOT NULL,
    "status" Status NOT NULL DEFAULT Status."open",
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
);
ALTER TABLE "complaints"
ADD PRIMARY KEY("id");
CREATE TYPE "Work_Category" AS ENUM (
    'plumbing',
    'electric',
    'carpentry',
    'hvac',
    'other'
);
CREATE TYPE "Work_Status" AS ENUM ();
CREATE TABLE "work_orders"(
    "id" BIGINT GENERATED ALWAYS AS IDENTITY,
    "created_by" BIGINT NOT NULL,
    "order_number" SERIAL NOT NULL,
    "category" Work_Category NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "description" TEXT NOT NULL,
    "unit_number" SMALLINT NOT NULL,
    "status" Status NOT NULL DEFAULT Status.'open',
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
);
ALTER TABLE "work_orders"
ADD PRIMARY KEY("id");
CREATE TYPE "Account_Status" AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE "Role" AS ENUM ('tenant', 'admin', 'landlord');
CREATE TABLE "users"(
    "id" BIGINT GENERATED ALWAYS AS IDENTITY,
    "clerk_id" UUID NOT NULL,
    "first_name" VARCHAR(255) NOT NULL,
    "last_name" VARCHAR(255) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "phone" VARCHAR(255) NULL,
    "unit_number" SMALLINT NULL,
    "role" "Role" NOT NULL DEFAULT "Role".'tenant',
    "status" Account_Status NOT NULL DEFAULT Account_Status.'active',
    "last_login" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
);
CREATE INDEX "user_clerk_id_index" ON "users"("clerk_id");
CREATE INDEX "user_unit_number_index" ON "users"("unit_number");
ALTER TABLE "users"
ADD PRIMARY KEY("id");
COMMENT ON COLUMN "users"."clerk_id" IS 'provided by Clerk';
CREATE TABLE "apartments"(
    "id" BIGINT GENERATED ALWAYS AS IDENTITY,
    "unit_number" SMALLINT NOT NULL,
    "price" TEXT NOT NULL,
    "size" SMALLINT NOT NULL,
    "tenants" BIGINT [] DEFAULT NULL,
    "management_id" BIGINT NOT NULL,
    "availability" BOOLEAN NOT NULL DEFAULT "0",
    "lease_id" BIGINT NOT NULL,
    "lease_satart_date" DATE NOT NULL,
    "lease_end_date" DATE NOT NULL,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
);
CREATE INDEX "apartment_unit_number_index" ON "apartments"("unit_number");
ALTER TABLE "apartments"
ADD PRIMARY KEY("id");
COMMENT ON COLUMN "apartments"."unit_number" IS 'describes as <building><floor><door> -> 2145';
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
CREATE TABLE "leases"(
    "id" BIGINT GENERATED ALWAYS AS IDENTITY,
    "document_name" TEXT NOT NULL,
    "document_type" "Type" NOT NULL,
    "file_type" VARCHAR(255) NOT NULL,
    "file_path" VARCHAR(255) NOT NULL,
    "file_size" INTEGER NULL,
    "checksum" TEXT NULL,
    "content_hash" TEXT NULL,
    "version_number" TEXT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT '1',
    "is_template" BOOLEAN NOT NULL DEFAULT '0',
    "lease_number" SERIAL NOT NULL,
    "lease_status" Lease_Status NOT NULL DEFAULT 'draft',
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "effective_date" TIMESTAMP(0) WITHOUT TIME ZONE NULL,
    "expiration_date" TIMESTAMP(0) WITHOUT TIME ZONE NULL,
    "created_by" BIGINT NOT NULL,
    "updated_by" BIGINT NOT NULL,
    "view_count" INTEGER NOT NULL DEFAULT '0',
    "download_count" INTEGER NOT NULL DEFAULT '0',
    "last_viewed_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL,
    "apartment_id" BIGINT NOT NULL,
    "tenant" BIGINT NOT NULL,
    "landlord" BIGINT NOT NULL,
    "tags" TEXT NULL,
    "custom_metadata" jsonb NULL,
    "is_signed" BOOLEAN NOT NULL DEFAULT '0',
    "signature_metadata" jsonb NULL,
    "compliance_status" Compliance_Status NOT NULL
);
CREATE INDEX "lease_lease_number_index" ON "leases"("lease_number");
CREATE INDEX "lease_apartment_id_index" ON "leases"("apartment_id")
ALTER TABLE "leases"
ADD PRIMARY KEY("id");
COMMENT ON COLUMN "leases"."document_type" IS 'amendment?';
COMMENT ON COLUMN "leases"."file_size" IS 'size in Bytes';
COMMENT ON COLUMN "leases"."lease_number" IS 'autoincremented';
COMMENT ON COLUMN "leases"."tenant" IS 'Type: Array Foreign keys of tenant users';
COMMENT ON COLUMN "leases"."tags" IS 'Type: string Array';
ALTER TABLE "parking_permits"
ADD CONSTRAINT "parkingpermit_created_by_foreign" FOREIGN KEY("created_by") REFERENCES "users"("id");
ALTER TABLE "apartments"
ADD CONSTRAINT "apartment_management_id_foreign" FOREIGN KEY("management_id") REFERENCES "users"("id");
ALTER TABLE "leases"
ADD CONSTRAINT "lease_created_by_foreign" FOREIGN KEY("created_by") REFERENCES "users"("id");
ALTER TABLE "complaints"
ADD CONSTRAINT "complaint_created_by_foreign" FOREIGN KEY("created_by") REFERENCES "users"("id");
ALTER TABLE "leases"
ADD CONSTRAINT "lease_apartment_id_foreign" FOREIGN KEY("apartment_id") REFERENCES "apartments"("id");
ALTER TABLE "apartments"
ADD CONSTRAINT "apartment_tenant_id_foreign" FOREIGN KEY("tenants") REFERENCES "users"("id");
ALTER TABLE "leases"
ADD CONSTRAINT "lease_updated_by_foreign" FOREIGN KEY("updated_by") REFERENCES "users"("id");
ALTER TABLE "leases"
ADD CONSTRAINT "lease_tenant_foreign" FOREIGN KEY("tenants") REFERENCES "users"("id");
ALTER TABLE "work_orders"
ADD CONSTRAINT "workorder_created_by_foreign" FOREIGN KEY("created_by") REFERENCES "users"("id");
ALTER TABLE "leases"
ADD CONSTRAINT "lease_landlord_foreign" FOREIGN KEY("landlord") REFERENCES "users"("id");