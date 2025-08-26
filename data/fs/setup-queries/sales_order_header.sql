-- Drop if exist
-- DROP TABLE IF EXISTS wms.sales_order_header;
-- DROP TABLE IF EXISTS wms.sales_order_history;
-- DROP FUNCTION IF EXISTS wms.sales_order_trigger;


-- Create sales_order_header table
CREATE TABLE IF NOT EXISTS wms.sales_order_header(
    id SERIAL PRIMARY KEY,
    entry_no VARCHAR(6) NOT NULL UNIQUE,
    entry_dt TIMESTAMP NOT NULL,
    party_id  INTEGER NOT NULL REFERENCES wms.party(id),
    broker_id INTEGER REFERENCES wms.broker(id),
    delivery_at_id INTEGER NOT NULL REFERENCES wms.address(id),
    trsp_id INTEGER NOT NULL REFERENCES wms.transport(id),
    year_code VARCHAR(4) NOT NULL,
    delivery_dt TIMESTAMP,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active boolean NOT NULL DEFAULT true,
    status VARCHAR(255),
    remarks VARCHAR(255),
);

-- Create temporal table for sales_order_header
CREATE TABLE IF NOT EXISTS wms.sales_order_header_history(
    history_id SERIAL PRIMARY KEY,
    sales_order_id INTEGER,
    entry_no VARCHAR(6),
    entry_dt TIMESTAMP,
    party_id INTEGER,
    broker_id INTEGER,
    delivery_at_id INTEGER,
    trsp_id INTEGER,
    year_code VARCHAR(4),
    delivery_dt TIMESTAMP,
    status VARCHAR(255),
    remarks VARCHAR(255),
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Create trigger function for sales_order_header
CREATE OR REPLACE FUNCTION wms.sales_order_header_trigger()
RETURN TRIGGER AS $$
BEGIN 
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.sales_order_header_history(
            sales_order_id,
            entry_no,
            entry_dt,
            party_id,
            broker_id,
            delivery_at_id,
            trsp_id,
            year_code,
            delivery_dt,
            status,
            remarks,
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id,
            NEW.entry_no,
            NEW.entry_dt,
            NEW.party_id,
            NEW.broker_id,
            NEW.delivery_at_id,
            NEW.trsp_id,
            NEW.year_code,
            NEW.delivery_dt,
            NEW.status,
            NEW.remarks,
            'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.sales_order_header_history(
                sales_order_id,
                entry_no,
                entry_dt,
                party_id,
                broker_id,
                delivery_at_id,
                trsp_id,
                year_code,
                delivery_dt,
                status,
                remarks,
                operation, operation_at, operation_by
            )
            VALUES (
                NEW.id,
                NEW.entry_no,
                NEW.entry_dt,
                NEW.party_id,
                NEW.broker_id,
                NEW.delivery_at_id,
                NEW.trsp_id,
                NEW.year_code,
                NEW.delivery_dt,
                NEW.status,
                NEW.remarks,
                'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.sales_order_header_history(
                sales_order_id,
                entry_no,
                entry_dt,
                party_id,
                broker_id,
                delivery_at_id,
                trsp_id,
                year_code,
                delivery_dt,
                status,
                remarks,
                operation, operation_at, operation_by
            )
            VALUES (
                NEW.id,
                NEW.entry_no,
                NEW.entry_dt,
                NEW.party_id,
                NEW.broker_id,
                NEW.delivery_at_id,
                NEW.trsp_id,
                NEW.year_code,
                NEW.delivery_dt,
                NEW.status,
                NEW.remarks,
                'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO wms.sales_order_header_history(
            sales_order_id,
            entry_no,
            entry_dt,
            party_id,
            broker_id,
            delivery_at_id,
            trsp_id,
            year_code,
            delivery_dt,
            status,
            remarks,
            operation, operation_at, operation_by
        )
        VALUES (
            OLD.id,
            OLD.entry_no,
            OLD.entry_dt,
            OLD.party_id,
            OLD.broker_id,
            OLD.delivery_at_id,
            OLD.trsp_id,
            OLD.year_code,
            OLD.delivery_dt,
            OLD.status,
            OLD.remarks,
            'DELETE', NEW.lua, NEW.lub
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for sales_order_header
DROP TRIGGER IF EXISTS sales_order_insert_trigger ON wms.sales_order_header;
CREATE TRIGGER sales_order_insert_trigger
    BEFORE INSERT ON wms.sales_order_header
    FOR EACH ROW
    EXECUTE FUNCTION wms.sales_order_trigger();

DROP TRIGGER IF EXISTS sales_order_update_trigger ON wms.sales_order_header;
CREATE TRIGGER sales_order_update_trigger
    BEFORE UPDATE ON wms.sales_order_header
    FOR EACH ROW
    EXECUTE FUNCTION wms.sales_order_header_trigger();

DROP TRIGGER IF EXISTS sales_order_delete_trigger ON wms.sales_order_header;
CREATE TRIGGER sales_order_delete_trigger
    BEFORE DELETE ON wms.sales_order_header
    FOR EACH ROW
    EXECUTE FUNCTION wms.sales_order_header_trigger();