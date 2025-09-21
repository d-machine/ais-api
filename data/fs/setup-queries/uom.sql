-- Create the main table for Unit of Measurement
CREATE TABLE IF NOT EXISTS wms.uom (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    descr VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true, -- Used for soft deletes
    lub INT REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create the history table to audit changes to uom
CREATE TABLE IF NOT EXISTS wms.uom_history (
    history_id SERIAL PRIMARY KEY,
    uom_id INTEGER,
    name VARCHAR(255),
    descr VARCHAR(255),
    is_active boolean NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INT REFERENCES administration.user(id)
);

-- Trigger function to log all INSERT and UPDATE operations
CREATE OR REPLACE FUNCTION wms.log_uom_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.uom_history (uom_id, name, descr, is_active, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.name, NEW.descr, NEW.is_active, 'INSERT', NEW.lua, NEW.lub);

    ELSIF TG_OP = 'UPDATE' THEN
        -- If the record is being deactivated, log it as a 'DELETE' operation for clarity
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.uom_history (uom_id, name, descr, is_active, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.name, NEW.descr, NEW.is_active, 'DELETE', NEW.lua, NEW.lub);
        ELSE
            INSERT INTO wms.uom_history (uom_id, name, descr, is_active, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.name, NEW.descr, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Assign trigger function to uom table
DROP TRIGGER IF EXISTS uom_insert_trigger ON wms.uom;
CREATE TRIGGER uom_insert_trigger
    AFTER INSERT ON wms.uom
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_uom_changes();

DROP TRIGGER IF EXISTS uom_update_trigger ON wms.uom;
CREATE TRIGGER uom_update_trigger
    AFTER UPDATE ON wms.uom
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_uom_changes();

-- Custom function to perform a "soft delete" by setting is_active to false
CREATE OR REPLACE FUNCTION wms.delete_uom(
    uom_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    UPDATE wms.uom
    SET is_active = false,
        lub = deleted_by_user_id,
        lua = NOW()
    WHERE id = uom_id_to_delete;
END;
$$ LANGUAGE plpgsql;