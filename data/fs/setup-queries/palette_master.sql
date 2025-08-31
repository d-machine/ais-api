-- DROP if exists
-- DROP TABLE IF EXISTS wms.palette_master;
-- DROP TABLE IF EXISTS wms.palette_master_history;
-- DROP TABLE IF EXISTS wms.palette_master_trigger;

-- Create palette_master table
CREATE TABLE IF NOT EXISTS wms.palette_master (
    id SERIAL PRIMARY KEY,
    descr VARCHAR(255),
    is_active boolean NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create temporal table for palette_master
CREATE TABLE IF NOT EXISTS wms.palette_master_history(
    history_id SERIAL PRIMARY KEY,
    palette_id INTEGER,
    descr VARCHAR(255),
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Create trigger function for palette_master
CREATE OR REPLACE FUNCTION wms.palette_master_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.palette_master_history(palette_id,descr,operation,operation_at,operation_by)
        VALUES(NEW.id,NEW.descr,'INSERT',NEW.lua,NEW.lub);
    
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.palette_master_history(palette_id,descr,operation,operation_at,operation_by)
            VALUES(NEW.id,NEW.descr,'INSERT',NEW.lua,NEW.lub);
        ELSE 
            INSERT INTO wms.palette_master_history(palette_id,descr,operation,operation_at,operation_by)
            VALUES(NEW.id,NEW.descr,'INSERT',NEW.lua,NEW.lub);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for palette_master
DROP TRIGGER IF EXISTS palette_master_insert_trigger ON wms.palette_master;
CREATE TRIGGER palette_master_insert_trigger
    AFTER INSERT ON wms.palette_master
    FOR EACH ROW
    EXECUTE FUNCTION wms.palette_master_trigger();

DROP TRIGGER IF EXISTS palette_master_update_trigger ON wms.palette_master;
CREATE TRIGGER palette_master_update_trigger
    AFTER UPDATE ON wms.palette_master
    FOR EACH ROW
    EXECUTE FUNCTION wms.palette_master_trigger();

DROP TRIGGER IF EXISTS palette_master_delete_trigger ON wms.palette_master;
CREATE TRIGGER palette_master_delete_trigger
    AFTER DELETE ON wms.palette_master
    FOR EACH ROW
    EXECUTE FUNCTION wms.palette_master_trigger();