-- Drop existing objects
-- DROP TRIGGER IF EXISTS resource_insert_trigger ON administration.resource;
-- DROP TRIGGER IF EXISTS resource_update_trigger ON administration.resource;
-- DROP FUNCTION IF EXISTS administration.log_resource_changes();
-- DROP FUNCTION IF EXISTS administration.delete_resource(INTEGER, INTEGER);
-- DROP TABLE IF EXISTS administration.resource_history;
-- DROP TABLE IF EXISTS administration.resource;

-- Create resource table
CREATE TABLE IF NOT EXISTS administration.resource (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    list_config_file VARCHAR(255),
    parent_id int NOT NULL,
    is_active boolean not null default true,
    lub int REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create history table
CREATE TABLE IF NOT EXISTS administration.resource_history (
    history_id SERIAL PRIMARY KEY,
    resource_id INT,
    name VARCHAR(255),
    list_config_file VARCHAR(255),
    parent_id int NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by int REFERENCES administration.user(id)
);

-- Create trigger function
CREATE OR REPLACE FUNCTION administration.log_resource_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO administration.resource_history (resource_id, name, list_config_file, parent_id, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.name, NEW.list_config_file, NEW.parent_id, 'INSERT', NEW.lua, NEW.lub);
    ELSIF TG_OP = 'UPDATE' THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO administration.resource_history (resource_id, name, list_config_file, parent_id, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.name, NEW.list_config_file, NEW.parent_id, 'DELETE', NEW.lua, NEW.lub);
        ELSE
            INSERT INTO administration.resource_history (resource_id, name, list_config_file, parent_id, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.name, NEW.list_config_file, NEW.parent_id, 'UPDATE', NEW.lua, NEW.lub);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS resource_insert_trigger ON administration.resource;
CREATE TRIGGER resource_insert_trigger
    AFTER INSERT ON administration.resource
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_resource_changes();

DROP TRIGGER IF EXISTS resource_update_trigger ON administration.resource;
CREATE TRIGGER resource_update_trigger
    AFTER UPDATE ON administration.resource
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_resource_changes();

-- Custom delete function
CREATE OR REPLACE FUNCTION administration.delete_resource(
    resource_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    -- Insert into history before deletion
    INSERT INTO administration.resource_history (
        resource_id, name, list_config_file, parent_id,
        operation, operation_at, operation_by
    )
    SELECT 
        id, name, list_config_file, parent_id,
        'DELETE', NOW(), deleted_by_user_id
    FROM administration.resource
    WHERE id = resource_id_to_delete;

    -- Delete the resource
    DELETE FROM administration.resource WHERE id = resource_id_to_delete;
END;
$$ LANGUAGE plpgsql; 