-- Drop table if exists
-- DROP TABLE IF EXISTS wms.country_master;
-- DROP TABLE IF EXISTS wms.country_master_history;
-- DROP FUNCTION IF EXISTS wms.country_master_trigger;
-- DROP FUNCTION IF EXISTS wms.delete_country_master;

-- Create country_master table
CREATE TABLE IF NOT EXISTS wms.country_master (
    id SERIAL PRIMARY KEY,
    country_name VARCHAR(255) NOT NULL,
    country_code VARCHAR(3) NOT NULL UNIQUE,
    description VARCHAR(255),
    is_active boolean not null default true,
    lub integer references administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create temporal table for country_master
CREATE TABLE IF NOT EXISTS wms.country_master_history (
    history_id SERIAL PRIMARY KEY,
    country_master_id INTEGER,
    country_name VARCHAR(255) NOT NULL,
    country_code VARCHAR(3) NOT NULL,
    description VARCHAR(255),
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Create trigger function for country_master
CREATE OR REPLACE FUNCTION wms.country_master_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.country_master_history (country_master_id,country_name,country_code,description,operation,operation_at,operation_by)
        VALUES (NEW.id,NEW.country_name,NEW.country_code,NEW.description,'INSERT',NEW.lua,NEW.lub);
    ELSIF TG_OP = 'UPDATE' THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.country_master_history (country_master_id,country_name,country_code,description,operation,operation_at,operation_by)
            VALUES (NEW.id,NEW.country_name,NEW.country_code,NEW.description,'DELETE',NEW.lua,NEW.lub);
        ELSE
            INSERT INTO wms.country_master_history (country_master_id,country_name,country_code,description,operation,operation_at,operation_by)
            VALUES (NEW.id,NEW.country_name,NEW.country_code,NEW.description,'UPDATE',NEW.lua,NEW.lub);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for country_master
DROP TRIGGER IF EXISTS country_master_insert_trigger ON wms.country_master;
CREATE TRIGGER country_master_insert_trigger
    AFTER INSERT ON wms.country_master
    FOR EACH ROW
    EXECUTE FUNCTION wms.country_master_trigger();

DROP TRIGGER IF EXISTS country_master_update_trigger ON wms.country_master;
CREATE TRIGGER country_master_update_trigger
    AFTER UPDATE ON wms.country_master
    FOR EACH ROW
    EXECUTE FUNCTION wms.country_master_trigger();
