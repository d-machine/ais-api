-- Create the main table for Unit of Measurement
CREATE TABLE IF NOT EXISTS wms.uom_master (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true, -- Used for soft deletes
    lub INT REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create the history table to audit changes to uom_master
CREATE TABLE IF NOT EXISTS wms.uom_master_history (
    history_id SERIAL PRIMARY KEY,
    uom_master_id INTEGER,
    name VARCHAR(255),
    description VARCHAR(255),
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INT REFERENCES administration.user(id)
);

-- Trigger function to log all INSERT and UPDATE operations
CREATE OR REPLACE FUNCTION wms.log_uom_master_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.uom_master_history (uom_master_id, name, description, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.name, NEW.description, 'INSERT', NEW.lua, NEW.lub);

    ELSIF TG_OP = 'UPDATE' THEN
        -- If the record is being deactivated, log it as a 'DELETE' operation for clarity
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.uom_master_history (uom_master_id, name, description, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.name, NEW.description, 'DELETE', NEW.lua, NEW.lub);
        ELSE
            INSERT INTO wms.uom_master_history (uom_master_id, name, description, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.name, NEW.description, 'UPDATE', NEW.lua, NEW.lub);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Assign trigger function to uom_master table
DROP TRIGGER IF EXISTS uom_master_insert_trigger ON wms.uom_master;
CREATE TRIGGER uom_master_insert_trigger
    AFTER INSERT ON wms.uom_master
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_uom_master_changes();

DROP TRIGGER IF EXISTS uom_master_update_trigger ON wms.uom_master;
CREATE TRIGGER uom_master_update_trigger
    AFTER UPDATE ON wms.uom_master
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_uom_master_changes();

-- Custom function to perform a "soft delete" by setting is_active to false
CREATE OR REPLACE FUNCTION wms.delete_uom_master(
    uom_master_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    UPDATE wms.uom_master
    SET is_active = false,
        lub = deleted_by_user_id,
        lua = NOW()
    WHERE id = uom_master_id_to_delete;
END;
$$ LANGUAGE plpgsql;