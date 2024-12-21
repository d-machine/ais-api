-- Drop existing objects
-- DROP TRIGGER IF EXISTS user_insert_trigger ON administration.user;
-- DROP TRIGGER IF EXISTS user_update_trigger ON administration.user;
-- DROP FUNCTION IF EXISTS administration.log_user_changes();
-- DROP FUNCTION IF EXISTS administration.delete_user(INTEGER, INTEGER);
-- DROP TABLE IF EXISTS administration.user_history;
-- DROP TABLE IF EXISTS administration.user;

-- Create user table
CREATE TABLE IF NOT EXISTS administration.user (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    last_updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_updated_by int not null
);

-- Create history table
CREATE TABLE IF NOT EXISTS administration.user_history (
    history_id SERIAL PRIMARY KEY,
    user_id INT,
    email VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    username VARCHAR(255),
    password VARCHAR(255),
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by int not null
);

-- Create trigger function
CREATE OR REPLACE FUNCTION administration.log_user_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO administration.user_history (user_id, email, first_name, last_name, username, password, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.email, NEW.first_name, NEW.last_name, NEW.username, NEW.password, 'INSERT', NEW.last_updated_at, NEW.last_updated_by);
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO administration.user_history (user_id, email, first_name, last_name, username, password, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.email, NEW.first_name, NEW.last_name, NEW.username, NEW.password, 'UPDATE', NEW.last_updated_at, NEW.last_updated_by);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS user_insert_trigger ON administration.user;
CREATE TRIGGER user_insert_trigger
    AFTER INSERT ON administration.user
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_user_changes();

DROP TRIGGER IF EXISTS user_update_trigger ON administration.user;
CREATE TRIGGER user_update_trigger
    AFTER UPDATE ON administration.user
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_user_changes();

-- Custom delete function
CREATE OR REPLACE FUNCTION administration.delete_user(
    user_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    -- Insert into history before deletion
    INSERT INTO administration.user_history (
        user_id, email, first_name, last_name, username, password,
        operation, operation_at, operation_by
    )
    SELECT 
        id, email, first_name, last_name, username, password,
        'DELETE', NOW(), deleted_by_user_id
    FROM administration.user
    WHERE id = user_id_to_delete;

    -- Delete the user
    DELETE FROM administration.user WHERE id = user_id_to_delete;
END;
$$ LANGUAGE plpgsql;
