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
    reports_to int NOT NULL,
    is_active boolean not null default true,
    lub int NOT NULL,
    lua TIMESTAMP NOT NULL DEFAULT NOW()
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
    reports_to int NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by int not null
);

-- Create trigger function
CREATE OR REPLACE FUNCTION administration.log_user_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO administration.user_history (user_id, email, first_name, last_name, username, password, reports_to, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.email, NEW.first_name, NEW.last_name, NEW.username, NEW.password, NEW.reports_to, 'INSERT', NEW.lua, NEW.lub);
    ELSIF TG_OP = 'UPDATE' THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO administration.user_history (user_id,email,first_name,last_name,username,password,reports_to, operation,operation_at,operation_by)
            VALUES (NEW.id,NEW.email,NEW.first_name,NEW.last_name,NEW.username,NEW.password,NEW.reports_to,'DELETE',NEW.lua,NEW.lub);
        ELSE IF (OLD.is_active = false AND NEW.is_active = true) THEN
            INSERT INTO administration.user_history (user_id,email,first_name,last_name,username,password,reports_to, operation,operation_at,operation_by)
            VALUES (NEW.id,NEW.email,NEW.first_name,NEW.last_name,NEW.username,NEW.password,NEW.reports_to,'RECOVER',NEW.lua,NEW.lub);
        ELSE
            INSERT INTO administration.user_history (user_id,email,first_name,last_name,username,password,reports_to, operation,operation_at,operation_by)
            VALUES (NEW.id,NEW.email,NEW.first_name,NEW.last_name,NEW.username,NEW.password,NEW.reports_to,'UPDATE',NEW.lua,NEW.lub);
        END IF;
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
