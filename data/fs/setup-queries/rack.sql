-- Drop old rack tables if they exist
DROP TABLE IF EXISTS wms.rack_history CASCADE;
DROP TABLE IF EXISTS wms.rack CASCADE;

-- Create the main table for Rack/Location
CREATE TABLE IF NOT EXISTS wms.rack (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    descr VARCHAR(255),
    capacity DECIMAL(15,3),
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    remarks VARCHAR(255)
);

-- Create the history table to audit changes to rack
CREATE TABLE IF NOT EXISTS wms.rack_history (
    history_id SERIAL PRIMARY KEY,
    rack_id INTEGER,
    code VARCHAR(50),
    name VARCHAR(255),
    descr VARCHAR(255),
    capacity DECIMAL(15,3),
    is_active BOOLEAN NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Trigger function to log all INSERT and UPDATE operations
DROP FUNCTION IF EXISTS wms.log_rack_changes();
CREATE OR REPLACE FUNCTION wms.log_rack_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.rack_history (
            rack_id, code, name, descr, capacity, is_active,
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.code, NEW.name, NEW.descr, NEW.capacity, NEW.is_active,
            'INSERT', NEW.lua, NEW.lub
        );

    ELSIF TG_OP = 'UPDATE' THEN
        -- If the record is being deactivated, log it as a 'DELETE' operation for clarity
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.rack_history (
                rack_id, code, name, descr, capacity, is_active,
                operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.code, NEW.name, NEW.descr, NEW.capacity, NEW.is_active,
                'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.rack_history (
                rack_id, code, name, descr, capacity, is_active,
                operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.code, NEW.name, NEW.descr, NEW.capacity, NEW.is_active,
                'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Assign the trigger function to the rack table
DROP TRIGGER IF EXISTS rack_insert_trigger ON wms.rack;
CREATE TRIGGER rack_insert_trigger
    AFTER INSERT ON wms.rack
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_rack_changes();

DROP TRIGGER IF EXISTS rack_update_trigger ON wms.rack;
CREATE TRIGGER rack_update_trigger
    AFTER UPDATE ON wms.rack
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_rack_changes();
