-- Drop existing objects
-- DROP TRIGGER IF EXISTS user_role_insert_trigger ON administration.user_role;
-- DROP TRIGGER IF EXISTS user_role_update_trigger ON administration.user_role;
-- DROP FUNCTION IF EXISTS administration.log_user_role_changes();
-- DROP FUNCTION IF EXISTS administration.delete_user_role(INTEGER, INTEGER);
-- DROP TABLE IF EXISTS administration.user_role_history;
-- DROP TABLE IF EXISTS administration.user_role;

-- Create user_role table
CREATE TABLE IF NOT EXISTS administration.user_role (
    id SERIAL PRIMARY KEY,
    user_id int REFERENCES administration.user(id),
    role_id int REFERENCES administration.role(id),
    last_updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_updated_by int REFERENCES administration.user(id),
    UNIQUE(user_id, role_id)
);

-- Create history table
CREATE TABLE IF NOT EXISTS administration.user_role_history (
    history_id SERIAL PRIMARY KEY,
    user_role_id INT,
    user_id INT,
    role_id INT,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by int REFERENCES administration.user(id)
);

-- Create trigger function
CREATE OR REPLACE FUNCTION administration.log_user_role_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO administration.user_role_history (user_role_id, user_id, role_id, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.user_id, NEW.role_id, 'INSERT', NEW.last_updated_at, NEW.last_updated_by);
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO administration.user_role_history (user_role_id, user_id, role_id, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.user_id, NEW.role_id, 'UPDATE', NEW.last_updated_at, NEW.last_updated_by);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS user_role_insert_trigger ON administration.user_role;
CREATE TRIGGER user_role_insert_trigger
    AFTER INSERT ON administration.user_role
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_user_role_changes();

DROP TRIGGER IF EXISTS user_role_update_trigger ON administration.user_role;
CREATE TRIGGER user_role_update_trigger
    AFTER UPDATE ON administration.user_role
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_user_role_changes();
