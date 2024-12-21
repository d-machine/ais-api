-- Drop existing objects
-- DROP TRIGGER IF EXISTS access_type_insert_trigger ON administration.access_type;
-- DROP TRIGGER IF EXISTS access_type_update_trigger ON administration.access_type;
-- DROP FUNCTION IF EXISTS administration.log_access_type_changes();
-- DROP FUNCTION IF EXISTS administration.delete_access_type(INTEGER, INTEGER);
-- DROP TABLE IF EXISTS administration.access_type_history;
-- DROP TABLE IF EXISTS administration.access_type;

-- Create access_type table
CREATE TABLE IF NOT EXISTS administration.access_type (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description VARCHAR(255),
    last_updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_updated_by int REFERENCES administration.user(id)
);

-- Create history table
CREATE TABLE IF NOT EXISTS administration.access_type_history (
    history_id SERIAL PRIMARY KEY,
    access_type_id INT,
    name VARCHAR(255),
    description VARCHAR(255),
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by int REFERENCES administration.user(id)
);

-- Create trigger function
CREATE OR REPLACE FUNCTION administration.log_access_type_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO administration.access_type_history (access_type_id, name, description, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.name, NEW.description, 'INSERT', NEW.last_updated_at, NEW.last_updated_by);
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO administration.access_type_history (access_type_id, name, description, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.name, NEW.description, 'UPDATE', NEW.last_updated_at, NEW.last_updated_by);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS access_type_insert_trigger ON administration.access_type;
CREATE TRIGGER access_type_insert_trigger
    AFTER INSERT ON administration.access_type
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_access_type_changes();

DROP TRIGGER IF EXISTS access_type_update_trigger ON administration.access_type;
CREATE TRIGGER access_type_update_trigger
    AFTER UPDATE ON administration.access_type
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_access_type_changes();

-- Custom delete function
CREATE OR REPLACE FUNCTION administration.delete_access_type(
    access_type_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    -- Insert into history before deletion
    INSERT INTO administration.access_type_history (
        access_type_id, name, description,
        operation, operation_at, operation_by
    )
    SELECT 
        id, name, description,
        'DELETE', NOW(), deleted_by_user_id
    FROM administration.access_type
    WHERE id = access_type_id_to_delete;

    -- Delete the access_type
    DELETE FROM administration.access_type WHERE id = access_type_id_to_delete;
END;
$$ LANGUAGE plpgsql; 