-- Drop if exists
-- DROP TABLE IF EXISTS wms.purchase_order_header;
-- DROP TABLE IF EXISTS wms.purchase_order_history;
-- DROP TABLE IF EXISTS wms.purchase_order_header_history;

--Create purchase_order_header table
CREATE TABLE IF NOT EXISTS wms.purchase_order_header(
    id SERIAL PRIMARY KEY,
    entry_no VARCHAR(10) NOT NULL UNIQUE,
    entry_dt TIMESTAMP NOT NULL,
    vendor_id INTEGER NOT NULL REFERENCES wms.vendor(id),
    broker_id INTEGER REFERENCES wms.broker(id),
    delivery_at_id INTEGER NOT NULL REFERENCES wms.address(id),
    trsp_id INTEGER REFERENCES wms.transport(id),
    year_code VARCHAR(4) NOT NULL,
    delivery_dt TIMESTAMP,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active boolean NOT NULL DEFAULT true,
    status INTEGER NOT NULL DEFAULT 0,
    remarks VARCHAR(255)
);

-- Create temporal table for purchase_order_header
CREATE TABLE IF NOT EXISTS wms.purchase_order_header_history(
    history_id SERIAL PRIMARY KEY,
    purchase_header_id INTEGER,
    entry_no VARCHAR(10),
    entry_dt TIMESTAMP,
    vendor_id INTEGER,
    broker_id INTEGER,
    delivery_at_id INTEGER,
    trsp_id INTEGER,
    year_code VARCHAR(4),
    delivery_dt TIMESTAMP,
    status INTEGER,
    remarks VARCHAR(255),
    is_active boolean NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Create trigger function for purchase_order_header
CREATE OR REPLACE FUNCTION wms.purchase_order_header_trigger()
RETURNS TRIGGER AS $$
BEGIN 
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.purchase_order_header_history(
            purchase_header_id,
            entry_no,
            entry_dt,
            vendor_id,
            broker_id,
            delivery_at_id,
            trsp_id,
            year_code,
            delivery_dt,
            status,
            remarks,
            is_active,
            operation,operation_at,operation_by
        ) VALUES (
            NEW.id,
            NEW.entry_no,
            NEW.entry_dt,
            NEW.vendor_id,
            NEW.broker_id,
            NEW.delivery_at_id,
            NEW.trsp_id,
            NEW.year_code,
            NEW.delivery_dt,
            NEW.status,
            NEW.remarks,
            NEW.is_active,
            'INSERT',NEW.lua,NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.purchase_order_header_history(
                purchase_header_id,
                entry_no,
                entry_dt,
                vendor_id,
                broker_id,
                delivery_at_id,
                trsp_id,
                year_code,
                delivery_dt,
                status,
                remarks,
                is_active,
                operation,operation_at,operation_by
            ) VALUES (
                NEW.id,
                NEW.entry_no,
                NEW.entry_dt,
                NEW.vendor_id,
                NEW.broker_id,
                NEW.delivery_at_id,
                NEW.trsp_id,
                NEW.year_code,
                NEW.delivery_dt,
                NEW.status,
                NEW.remarks,
                NEW.is_active,
                'DELETE',NEW.lua,NEW.lub
            );
        ELSE
            INSERT INTO wms.purchase_order_header_history(
                purchase_header_id,
                entry_no,
                entry_dt,
                vendor_id,
                broker_id,
                delivery_at_id,
                trsp_id,
                year_code,
                delivery_dt,
                status,
                remarks,
                is_active,
                operation,operation_at,operation_by
            ) VALUES (
                NEW.id,
                NEW.entry_no,
                NEW.entry_dt,
                NEW.vendor_id,
                NEW.broker_id,
                NEW.delivery_at_id,
                NEW.trsp_id,
                NEW.year_code,
                NEW.delivery_dt,
                NEW.status,
                NEW.remarks,
                NEW.is_active,
                'UPDATE',NEW.lua,NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS purchase_order_insert_trigger ON wms.purchase_order_header;
CREATE TRIGGER purchase_order_insert_trigger
    AFTER INSERT ON wms.purchase_order_header
    FOR EACH ROW
    EXECUTE FUNCTION wms.purchase_order_header_trigger();

DROP TRIGGER IF EXISTS purchase_order_update_trigger ON wms.purchase_order_header;
CREATE TRIGGER purchase_order_update_trigger
    AFTER UPDATE ON wms.purchase_order_header     
    FOR EACH ROW
    EXECUTE FUNCTION wms.purchase_order_header_trigger();

DROP TRIGGER IF EXISTS purchase_order_delete_trigger ON wms.purchase_order_header;
CREATE TRIGGER purchase_order_delete_trigger
    AFTER DELETE ON wms.purchase_order_header
    FOR EACH ROW
    EXECUTE FUNCTION wms.purchase_order_header_trigger();