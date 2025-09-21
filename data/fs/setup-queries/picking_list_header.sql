-- DROP IF EXISTS
-- DROP TABLE IF EXISTS wms.picking_list_header;
-- DROP TABLE IF EXIST wms.picking_list_header_history;
-- DROP TABLE IF EXIST wms.picking _list_header_trigger;

-- Create picking_list_header table
CREATE TABLE IF NOT EXISTS wms.picking_list_header(
    id SERIAL PRIMARY KEY,
    party_id INTEGER NOT NULL REFERENCES wms.party(id),
    descr VARCHAR(255),
    is_active boolean NOT NULL DEFAULT true,
    lub INTEGER references administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    status VARCHAR(255)
);

-- Create temporal table for picking_list_header
CREATE TABLE IF NOT EXISTS wms.picking_list_header_history(
    history_id SERIAL PRIMARY KEY,
    picking_list_id INTEGER,
    party_id INTEGER,
    descr VARCHAR(255),
    status VARCHAR(255),
    is_active boolean NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Create trigger function for picking_list_header
CREATE OR REPLACE FUNCTION wms.picking_list_header_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.picking_list_header_history(
            picking_list_id, party_id, descr, status, is_active, operation, operation_at, operation_by
        )
        VALUES(
            NEW.id, NEW.party_id, NEW.descr, NEW.status, NEW.is_active, 'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.picking_list_header_history(
                picking_list_id, party_id, descr, status, is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.party_id, NEW.descr, NEW.status, NEW.is_active, 'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.picking_list_header_history(
                picking_list_id, party_id, descr, status, is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.party_id, NEW.descr, NEW.status, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--Create trigger for picking_list_header
DROP TRIGGER IF EXISTS picking_list_insert_trigger ON wms.picking_list_header;
CREATE TRIGGER picking_list_insert_trigger
    AFTER INSERT ON wms.picking_list_header
    FOR EACH ROW
    EXECUTE FUNCTION wms.picking_list_header_trigger();

DROP TRIGGER IF EXISTS picking_list_update_trigger ON wms.picking_list_header;
CREATE TRIGGER picking_list_update_trigger
    AFTER UPDATE ON wms.picking_list_header
    FOR EACH ROW
    EXECUTE FUNCTION wms.picking_list_header_trigger();

DROP TRIGGER IF EXISTS picking_list_delete_trigger ON wms.picking_list_header;
CREATE TRIGGER picking_list_delete_trigger
    AFTER DELETE ON wms.picking_list_header
    FOR EACH ROW
    EXECUTE FUNCTION wms.picking_list_header_trigger();