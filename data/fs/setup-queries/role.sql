-- Drop existing objects
-- DROP TRIGGER IF EXISTS role_insert_trigger ON administration.role;
-- DROP TRIGGER IF EXISTS role_update_trigger ON administration.role;
-- DROP FUNCTION IF EXISTS administration.log_role_changes();
-- DROP FUNCTION IF EXISTS administration.delete_role(INTEGER, INTEGER);
-- DROP TABLE IF EXISTS administration.role_history;
-- DROP TABLE IF EXISTS administration.role;

-- Create role table
CREATE TABLE IF NOT EXISTS administration.role (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description VARCHAR(255),
    is_active boolean not null default true,
    lub int REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create history table
CREATE TABLE IF NOT EXISTS administration.role_history (
    history_id SERIAL PRIMARY KEY,
    role_id INT,
    name VARCHAR(255),
    description VARCHAR(255),
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by int REFERENCES administration.user(id)
);

-- Create trigger function
CREATE OR REPLACE FUNCTION administration.log_role_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO administration.role_history (role_id, name, description, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.name, NEW.description, 'INSERT', NEW.lua, NEW.lub);
    ELSIF TG_OP = 'UPDATE' THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO administration.role_history (role_id,name,description,operation,operation_at,operation_by)
            VALUES (NEW.id,NEW.name,NEW.description,'DELETE',NEW.lua,NEW.lub);
        ELSE
            INSERT INTO administration.role_history (role_id,name,description,operation,operation_at,operation_by)
            VALUES (NEW.id,NEW.name,NEW.description,'UPDATE',NEW.lua,NEW.lub);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS role_insert_trigger ON administration.role;
CREATE TRIGGER role_insert_trigger
    AFTER INSERT ON administration.role
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_role_changes();

DROP TRIGGER IF EXISTS role_update_trigger ON administration.role;
CREATE TRIGGER role_update_trigger
    AFTER UPDATE ON administration.role
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_role_changes();
