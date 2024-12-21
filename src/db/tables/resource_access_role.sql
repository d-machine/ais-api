-- Drop existing objects
-- DROP TRIGGER IF EXISTS resource_access_role_insert_trigger ON administration.resource_access_role;
-- DROP TRIGGER IF EXISTS resource_access_role_update_trigger ON administration.resource_access_role;
-- DROP FUNCTION IF EXISTS administration.log_resource_access_role_changes();
-- DROP FUNCTION IF EXISTS administration.delete_resource_access_role(INTEGER, INTEGER);
-- DROP TABLE IF EXISTS administration.resource_access_role_history;
-- DROP TABLE IF EXISTS administration.resource_access_role;

-- Create resource_access_role table
CREATE TABLE IF NOT EXISTS administration.resource_access_role (
    id SERIAL PRIMARY KEY,
    resource_id INTEGER REFERENCES administration.resource(id),
    access_type_id INTEGER REFERENCES administration.access_type(id),
    role_id INTEGER REFERENCES administration.role(id),
    last_updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_updated_by int REFERENCES administration.user(id),
    UNIQUE(resource_id, access_type_id, role_id)
);

-- Create history table
CREATE TABLE IF NOT EXISTS administration.resource_access_role_history (
    history_id SERIAL PRIMARY KEY,
    resource_access_role_id INT,
    resource_id INTEGER,
    access_type_id INTEGER,
    role_id INTEGER,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by int REFERENCES administration.user(id)
);

-- Create trigger function
CREATE OR REPLACE FUNCTION administration.log_resource_access_role_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO administration.resource_access_role_history (
            resource_access_role_id, resource_id, access_type_id, role_id,
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.resource_id, NEW.access_type_id, NEW.role_id,
            'INSERT', NEW.last_updated_at, NEW.last_updated_by
        );
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO administration.resource_access_role_history (
            resource_access_role_id, resource_id, access_type_id, role_id,
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.resource_id, NEW.access_type_id, NEW.role_id,
            'UPDATE', NEW.last_updated_at, NEW.last_updated_by
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS resource_access_role_insert_trigger ON administration.resource_access_role;
CREATE TRIGGER resource_access_role_insert_trigger
    AFTER INSERT ON administration.resource_access_role
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_resource_access_role_changes();

DROP TRIGGER IF EXISTS resource_access_role_update_trigger ON administration.resource_access_role;
CREATE TRIGGER resource_access_role_update_trigger
    AFTER UPDATE ON administration.resource_access_role
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_resource_access_role_changes();

-- Custom delete function
CREATE OR REPLACE FUNCTION administration.delete_resource_access_role(
    resource_access_role_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    -- Insert into history before deletion
    INSERT INTO administration.resource_access_role_history (
        resource_access_role_id, resource_id, access_type_id, role_id,
        operation, operation_at, operation_by
    )
    SELECT 
        id, resource_id, access_type_id, role_id,
        'DELETE', NOW(), deleted_by_user_id
    FROM administration.resource_access_role
    WHERE id = resource_access_role_id_to_delete;

    -- Delete the resource_access_role
    DELETE FROM administration.resource_access_role WHERE id = resource_access_role_id_to_delete;
END;
$$ LANGUAGE plpgsql; 