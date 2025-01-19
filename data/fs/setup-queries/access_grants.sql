-- Drop existing objects
-- DROP TRIGGER IF EXISTS access_grants_insert_trigger ON administration.access_grants;
-- DROP TRIGGER IF EXISTS access_grants_update_trigger ON administration.access_grants;
-- DROP FUNCTION IF EXISTS administration.log_access_grants_changes();
-- DROP FUNCTION IF EXISTS administration.delete_access_grants(INTEGER, INTEGER);
-- DROP TABLE IF EXISTS administration.access_grants_history;
-- DROP TABLE IF EXISTS administration.access_grants;

-- Create access_grants table
CREATE TABLE IF NOT EXISTS administration.access_grants (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES administration.user(id),
    target_id INTEGER REFERENCES administration.user(id),
    access_type access_type,
    valid_from TIMESTAMP,
    valid_until TIMESTAMP,
    last_updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_updated_by int REFERENCES administration.user(id),
    UNIQUE(user_id, target_id, access_type)
);

-- Create history table
CREATE TABLE IF NOT EXISTS administration.access_grants_history (
    history_id SERIAL PRIMARY KEY,
    access_grant_id INT,
    user_id INTEGER,
    target_id INTEGER,
    access_type access_type,
    valid_from TIMESTAMP,
    valid_until TIMESTAMP,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by int REFERENCES administration.user(id)
);

-- Create trigger function
CREATE OR REPLACE FUNCTION administration.log_access_grants_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO administration.access_grants_history (access_grant_id, user_id, target_id, access_type, valid_from, valid_until, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.user_id, NEW.target_id, NEW.access_type, NEW.valid_from, NEW.valid_until, 'INSERT', NEW.last_updated_at, NEW.last_updated_by);
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO administration.access_grants_history (access_grant_id, user_id, target_id, access_type, valid_from, valid_until, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.user_id, NEW.target_id, NEW.access_type, NEW.valid_from, NEW.valid_until, 'UPDATE', NEW.last_updated_at, NEW.last_updated_by);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS access_grants_insert_trigger ON administration.access_grants;
CREATE TRIGGER access_grants_insert_trigger
    AFTER INSERT ON administration.access_grants
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_access_grants_changes();

DROP TRIGGER IF EXISTS access_grants_update_trigger ON administration.access_grants;
CREATE TRIGGER access_grants_update_trigger
    AFTER UPDATE ON administration.access_grants
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_access_grants_changes();

-- Custom delete function
CREATE OR REPLACE FUNCTION administration.delete_access_grants(
    access_grant_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    -- Insert into history before deletion
    INSERT INTO administration.access_grants_history (
        access_grant_id, user_id, target_id, access_type,
        valid_from, valid_until, operation, operation_at, operation_by
    )
    SELECT 
        id, user_id, target_id, access_type,
        valid_from, valid_until, 'DELETE', NOW(), deleted_by_user_id
    FROM administration.access_grants
    WHERE id = access_grant_id_to_delete;

    -- Delete the access_grant
    DELETE FROM administration.access_grants WHERE id = access_grant_id_to_delete;
END;
$$ LANGUAGE plpgsql; 