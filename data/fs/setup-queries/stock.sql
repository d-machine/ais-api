-- Drop old stock tables if they exist
DROP TABLE IF EXISTS wms.stock_history CASCADE;
DROP TABLE IF EXISTS wms.stock CASCADE;

-- Create the main table for Stock/Inventory
CREATE TABLE IF NOT EXISTS wms.stock (
    id SERIAL PRIMARY KEY,
    ean_id INTEGER NOT NULL REFERENCES wms.material_ean(id),
    rack_id INTEGER NOT NULL DEFAULT 0 REFERENCES wms.rack(id),
    qty DECIMAL(15,3) NOT NULL DEFAULT 0,
    uom_id INTEGER NOT NULL REFERENCES wms.uom(id),
    rate DECIMAL(15,2),
    expiry_dt DATE,
    batch_no VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    remarks VARCHAR(255),
    UNIQUE(batch_no, rack_id)
);

-- Note: rack_id = 0 means common area (not yet put away), rack_id > 0 means specific rack
-- Rows with qty = 0 are kept (not deleted)

-- Create the history table to audit changes to stock
CREATE TABLE IF NOT EXISTS wms.stock_history (
    history_id SERIAL PRIMARY KEY,
    stock_id INTEGER,
    ean_id INTEGER,
    rack_id INTEGER,
    qty DECIMAL(15,3),
    uom_id INTEGER,
    rate DECIMAL(15,2),
    expiry_dt DATE,
    batch_no VARCHAR(100),
    is_active BOOLEAN NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Trigger function to log all INSERT and UPDATE operations
DROP FUNCTION IF EXISTS wms.log_stock_changes();
CREATE OR REPLACE FUNCTION wms.log_stock_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.stock_history (
            stock_id, ean_id, rack_id, qty, uom_id, rate, expiry_dt, batch_no, is_active,
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.ean_id, NEW.rack_id, NEW.qty, NEW.uom_id, NEW.rate, NEW.expiry_dt, NEW.batch_no, NEW.is_active,
            'INSERT', NEW.lua, NEW.lub
        );

    ELSIF TG_OP = 'UPDATE' THEN
        -- If the record is being deactivated, log it as a 'DELETE' operation for clarity
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.stock_history (
                stock_id, ean_id, rack_id, qty, uom_id, rate, expiry_dt, batch_no, is_active,
                operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.ean_id, NEW.rack_id, NEW.qty, NEW.uom_id, NEW.rate, NEW.expiry_dt, NEW.batch_no, NEW.is_active,
                'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.stock_history (
                stock_id, ean_id, rack_id, qty, uom_id, rate, expiry_dt, batch_no, is_active,
                operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.ean_id, NEW.rack_id, NEW.qty, NEW.uom_id, NEW.rate, NEW.expiry_dt, NEW.batch_no, NEW.is_active,
                'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Assign the trigger function to the stock table
DROP TRIGGER IF EXISTS stock_insert_trigger ON wms.stock;
CREATE TRIGGER stock_insert_trigger
    AFTER INSERT ON wms.stock
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_stock_changes();

DROP TRIGGER IF EXISTS stock_update_trigger ON wms.stock;
CREATE TRIGGER stock_update_trigger
    AFTER UPDATE ON wms.stock
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_stock_changes();
