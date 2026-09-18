-- ==============================================================================
-- ENTERPRISE ASSET MANAGEMENT SYSTEM (EAMS) - POSTGRESQL SCHEMA
-- Features: Multi-Company (Tenant), Soft Deletes, Audit Columns, Foreign Keys
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 1. SCHEMAS
-- ==============================================================================
CREATE SCHEMA IF NOT EXISTS master;
CREATE SCHEMA IF NOT EXISTS asset;
CREATE SCHEMA IF NOT EXISTS trx;
CREATE SCHEMA IF NOT EXISTS audit;

-- ==============================================================================
-- 2. MASTER DATA
-- ==============================================================================

CREATE TABLE master.companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    tax_number VARCHAR(100),
    base_currency VARCHAR(3) DEFAULT 'IDR',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE master.branches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES master.companies(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(company_id, code)
);

CREATE TABLE master.departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES master.companies(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(company_id, code)
);

CREATE TABLE master.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES master.companies(id),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL, -- e.g., 'Super Admin', 'Group Admin', 'Asset Manager'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE master.asset_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES master.companies(id),
    code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    depreciation_method VARCHAR(50) NOT NULL DEFAULT 'Straight Line',
    default_useful_life_months INT NOT NULL,
    coa_asset VARCHAR(50),
    coa_accumulated_depreciation VARCHAR(50),
    coa_depreciation_expense VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(company_id, code)
);

-- ==============================================================================
-- 3. ASSET REGISTRY
-- ==============================================================================

CREATE TABLE asset.assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES master.companies(id),
    asset_code VARCHAR(100) NOT NULL,
    name VARCHAR(255) NOT NULL,
    category_id UUID NOT NULL REFERENCES master.asset_categories(id),
    branch_id UUID NOT NULL REFERENCES master.branches(id),
    department_id UUID REFERENCES master.departments(id),
    custodian_id UUID REFERENCES master.users(id),
    
    -- Financial Details
    acquisition_date DATE NOT NULL,
    acquisition_cost NUMERIC(18, 2) NOT NULL,
    residual_value NUMERIC(18, 2) DEFAULT 0,
    useful_life_months INT NOT NULL,
    depreciation_method VARCHAR(50) NOT NULL,
    
    -- Current Values
    current_book_value NUMERIC(18, 2) NOT NULL,
    accumulated_depreciation NUMERIC(18, 2) DEFAULT 0,
    
    -- Identifiers
    serial_number VARCHAR(100),
    machine_number VARCHAR(100),
    chassis_number VARCHAR(100),
    qr_code VARCHAR(255),
    barcode VARCHAR(255),
    
    -- Status
    status VARCHAR(50) DEFAULT 'Active', -- Active, Disposed, Maintenance, Transferring
    condition VARCHAR(50) DEFAULT 'Good',
    
    created_by UUID REFERENCES master.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(company_id, asset_code)
);

CREATE TABLE asset.asset_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id UUID NOT NULL REFERENCES asset.assets(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================================================
-- 4. TRANSACTIONS (DEPRECIATION)
-- ==============================================================================

CREATE TABLE trx.depreciation_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id UUID NOT NULL REFERENCES asset.assets(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES master.companies(id),
    period_year INT NOT NULL,
    period_month INT NOT NULL,
    depreciation_amount NUMERIC(18, 2) NOT NULL,
    accumulated_depreciation NUMERIC(18, 2) NOT NULL,
    book_value NUMERIC(18, 2) NOT NULL,
    is_posted BOOLEAN DEFAULT FALSE,
    posted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(asset_id, period_year, period_month)
);

-- ==============================================================================
-- 5. AUDIT TRAIL
-- ==============================================================================

CREATE TABLE audit.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES master.companies(id),
    user_id UUID REFERENCES master.users(id),
    action VARCHAR(20) NOT NULL, -- CREATE, UPDATE, DELETE
    table_name VARCHAR(100) NOT NULL,
    record_id UUID NOT NULL,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) SETUP EXAMPLE
-- ==============================================================================
-- RLS ensures that a user can only see data belonging to their company.

ALTER TABLE asset.assets ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy ON asset.assets
    USING (company_id = current_setting('app.current_tenant_id', true)::UUID);

-- (Repeat for other tables)
