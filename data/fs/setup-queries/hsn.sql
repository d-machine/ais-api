-- Drop old HSN tables if they exist
DROP TABLE IF EXISTS wms.hsn_history CASCADE;
DROP TABLE IF EXISTS wms.hsn CASCADE;

-- Create the HSN master table
CREATE TABLE IF NOT EXISTS wms.hsn (
    id SERIAL PRIMARY KEY,
    hsn_code VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255),
    cgst DECIMAL(5,2) NOT NULL DEFAULT 0,
    sgst DECIMAL(5,2) NOT NULL DEFAULT 0,
    igst DECIMAL(5,2) NOT NULL DEFAULT 0,
    utgst DECIMAL(5,2) NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create the history table to audit changes to hsn
CREATE TABLE IF NOT EXISTS wms.hsn_history (
    history_id SERIAL PRIMARY KEY,
    hsn_id INTEGER,
    hsn_code VARCHAR(20),
    descr VARCHAR(255),
    cgst DECIMAL(5,2),
    sgst DECIMAL(5,2),
    igst DECIMAL(5,2),
    utgst DECIMAL(5,2),
    is_active BOOLEAN NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Trigger function to log all INSERT and UPDATE operations
DROP FUNCTION IF EXISTS wms.log_hsn_changes();
CREATE OR REPLACE FUNCTION wms.log_hsn_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.hsn_history (
            hsn_id, hsn_code, descr, cgst, sgst, igst, utgst,
            is_active, operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.hsn_code, NEW.descr, NEW.cgst, NEW.sgst, NEW.igst, NEW.utgst,
            NEW.is_active, 'INSERT', NEW.lua, NEW.lub
        );

    ELSIF TG_OP = 'UPDATE' THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.hsn_history (
                hsn_id, hsn_code, descr, cgst, sgst, igst, utgst,
                is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.hsn_code, NEW.descr, NEW.cgst, NEW.sgst, NEW.igst, NEW.utgst,
                NEW.is_active, 'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.hsn_history (
                hsn_id, hsn_code, descr, cgst, sgst, igst, utgst,
                is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.hsn_code, NEW.descr, NEW.cgst, NEW.sgst, NEW.igst, NEW.utgst,
                NEW.is_active, 'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Assign the trigger function to the hsn table
DROP TRIGGER IF EXISTS hsn_insert_trigger ON wms.hsn;
CREATE TRIGGER hsn_insert_trigger
    AFTER INSERT ON wms.hsn
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_hsn_changes();

DROP TRIGGER IF EXISTS hsn_update_trigger ON wms.hsn;
CREATE TRIGGER hsn_update_trigger
    AFTER UPDATE ON wms.hsn
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_hsn_changes();
