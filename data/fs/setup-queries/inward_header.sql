-- Drop if exists
DROP TABLE IF EXISTS wms.inward_header_history CASCADE;
DROP TABLE IF EXISTS wms.inward_header CASCADE;

-- Create inward_header table
CREATE TABLE IF NOT EXISTS wms.inward_header (
    id SERIAL PRIMARY KEY,
    entry_no VARCHAR(50) NOT NULL UNIQUE,
    entry_dt DATE NOT NULL,
    vendor_id INTEGER NOT NULL REFERENCES wms.vendor(id),
    po_ids TEXT,
    invoice_no VARCHAR(100),
    invoice_dt DATE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    remarks VARCHAR(255)
);

-- Create temporal table for inward_header
CREATE TABLE IF NOT EXISTS wms.inward_header_history (
    history_id SERIAL PRIMARY KEY,
    inward_header_id INTEGER,
    entry_no VARCHAR(50),
    entry_dt DATE,
    vendor_id INTEGER,
    po_ids TEXT,
    invoice_no VARCHAR(100),
    invoice_dt DATE,
    is_active BOOLEAN NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Create trigger function for inward_header
CREATE OR REPLACE FUNCTION wms.inward_header_trigger()
RETURNS TRIGGER AS $$
BEGIN 
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.inward_header_history(
            inward_header_id, entry_no, entry_dt, vendor_id, po_ids,
            invoice_no, invoice_dt, is_active,
            operation, operation_at, operation_by
        ) VALUES (
            NEW.id, NEW.entry_no, NEW.entry_dt, NEW.vendor_id, NEW.po_ids,
            NEW.invoice_no, NEW.invoice_dt, NEW.is_active,
            'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.inward_header_history(
                inward_header_id, entry_no, entry_dt, vendor_id, po_ids,
                invoice_no, invoice_dt, is_active,
                operation, operation_at, operation_by
            ) VALUES (
                NEW.id, NEW.entry_no, NEW.entry_dt, NEW.vendor_id, NEW.po_ids,
                NEW.invoice_no, NEW.invoice_dt, NEW.is_active,
                'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.inward_header_history(
                inward_header_id, entry_no, entry_dt, vendor_id, po_ids,
                invoice_no, invoice_dt, is_active,
                operation, operation_at, operation_by
            ) VALUES (
                NEW.id, NEW.entry_no, NEW.entry_dt, NEW.vendor_id, NEW.po_ids,
                NEW.invoice_no, NEW.invoice_dt, NEW.is_active,
                'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS inward_header_insert_trigger ON wms.inward_header;
CREATE TRIGGER inward_header_insert_trigger
    AFTER INSERT ON wms.inward_header
    FOR EACH ROW
    EXECUTE FUNCTION wms.inward_header_trigger();

DROP TRIGGER IF EXISTS inward_header_update_trigger ON wms.inward_header;
CREATE TRIGGER inward_header_update_trigger
    AFTER UPDATE ON wms.inward_header     
    FOR EACH ROW
    EXECUTE FUNCTION wms.inward_header_trigger();

DROP TRIGGER IF EXISTS inward_header_delete_trigger ON wms.inward_header;
CREATE TRIGGER inward_header_delete_trigger
    AFTER DELETE ON wms.inward_header
    FOR EACH ROW
    EXECUTE FUNCTION wms.inward_header_trigger();
