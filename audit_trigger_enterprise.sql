-- ==============================================================================
-- ENTERPRISE ASSET MANAGEMENT SYSTEM (EAMS) - ENTERPRISE AUDIT TRAIL
-- Database-Level Audit Logging using PostgreSQL Triggers
-- ==============================================================================
-- Keunggulan: Menangkap SEMUA perubahan data (Insert, Update, Delete)
-- bahkan jika perubahan dilakukan langsung via database (bypass aplikasi).

-- 1. Tabel Audit sudah dibuat di skema awal (audit.audit_logs)
-- Pastikan ekstensi hstore aktif jika ingin manipulasi kompleks (opsional, kita pakai JSONB)

-- 2. Buat Fungsi Trigger General
CREATE OR REPLACE FUNCTION audit.if_modified_func() RETURNS TRIGGER AS $body$
DECLARE
    v_old_data JSONB;
    v_new_data JSONB;
    v_company_id UUID;
    v_record_id UUID;
    v_user_id UUID; -- Diambil dari session context aplikasi (misal via set_config)
BEGIN
    -- Coba ambil Company ID dan User ID dari row data jika ada, atau fallback ke context
    v_user_id := current_setting('app.current_user_id', true)::UUID;
    
    IF (TG_OP = 'UPDATE') THEN
        v_old_data := row_to_json(OLD)::JSONB;
        v_new_data := row_to_json(NEW)::JSONB;
        v_record_id := OLD.id;
        
        -- Hanya log jika ada data yang berubah
        IF v_old_data = v_new_data THEN
            RETURN NEW;
        END IF;

        INSERT INTO audit.audit_logs (company_id, user_id, action, table_name, record_id, old_values, new_values)
        VALUES (
            COALESCE(OLD.company_id, NEW.company_id, current_setting('app.current_tenant_id', true)::UUID),
            v_user_id,
            'UPDATE',
            TG_TABLE_NAME::TEXT,
            v_record_id,
            v_old_data,
            v_new_data
        );
        RETURN NEW;
        
    ELSIF (TG_OP = 'DELETE') THEN
        v_old_data := row_to_json(OLD)::JSONB;
        v_record_id := OLD.id;
        
        INSERT INTO audit.audit_logs (company_id, user_id, action, table_name, record_id, old_values, new_values)
        VALUES (
            COALESCE(OLD.company_id, current_setting('app.current_tenant_id', true)::UUID),
            v_user_id,
            'DELETE',
            TG_TABLE_NAME::TEXT,
            v_record_id,
            v_old_data,
            NULL
        );
        RETURN OLD;
        
    ELSIF (TG_OP = 'INSERT') THEN
        v_new_data := row_to_json(NEW)::JSONB;
        v_record_id := NEW.id;
        
        INSERT INTO audit.audit_logs (company_id, user_id, action, table_name, record_id, old_values, new_values)
        VALUES (
            COALESCE(NEW.company_id, current_setting('app.current_tenant_id', true)::UUID),
            v_user_id,
            'CREATE',
            TG_TABLE_NAME::TEXT,
            v_record_id,
            NULL,
            v_new_data
        );
        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$body$
LANGUAGE plpgsql;

-- 3. Menerapkan Trigger ke Tabel Kritis (Contoh: asset.assets)
DROP TRIGGER IF EXISTS audit_assets_trigger ON asset.assets;

CREATE TRIGGER audit_assets_trigger
AFTER INSERT OR UPDATE OR DELETE ON asset.assets
FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func();

-- Menerapkan ke Master Categories
DROP TRIGGER IF EXISTS audit_categories_trigger ON master.asset_categories;

CREATE TRIGGER audit_categories_trigger
AFTER INSERT OR UPDATE OR DELETE ON master.asset_categories
FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func();

-- ==============================================================================
-- CARA PENGGUNAAN OLEH APLIKASI (NestJS / Laravel):
-- Sebelum menjalankan transaksi UPDATE/INSERT, aplikasi harus set context:
-- EXECUTE 'SET LOCAL app.current_user_id = ''uuid-user-login-disini''';
-- EXECUTE 'SET LOCAL app.current_tenant_id = ''uuid-company-disini''';
-- ==============================================================================
