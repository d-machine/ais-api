-- DROP if exists
-- DROP TABLE IF EXISTS wms.palette;
-- DROP TABLE IF EXISTS wms.palette_history;
-- DROP TABLE IF EXISTS wms.palette_trigger;

-- Create palette table
CREATE TABLE IF NOT EXISTS wms.palette (
    id SERIAL PRIMARY KEY,
    descr VARCHAR(255),
    is_active boolean NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create temporal table for palette
CREATE TABLE IF NOT EXISTS wms.palette_history(
    history_id SERIAL PRIMARY KEY,
    palette_id INTEGER,
    descr VARCHAR(255),
    is_active boolean NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Create trigger function for palette
CREATE OR REPLACE FUNCTION wms.palette_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.palette_history(palette_id, descr, is_active, operation, operation_at, operation_by)
        VALUES(NEW.id, NEW.descr, NEW.is_active, 'INSERT', NEW.lua, NEW.lub);
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.palette_history(palette_id, descr, is_active, operation, operation_at, operation_by)
            VALUES(NEW.id, NEW.descr, NEW.is_active, 'DELETE', NEW.lua, NEW.lub);
        ELSE 
            INSERT INTO wms.palette_history(palette_id, descr, is_active, operation, operation_at, operation_by)
            VALUES(NEW.id, NEW.descr, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for palette
DROP TRIGGER IF EXISTS palette_insert_trigger ON wms.palette;
CREATE TRIGGER palette_insert_trigger
    AFTER INSERT ON wms.palette
    FOR EACH ROW
    EXECUTE FUNCTION wms.palette_trigger();

DROP TRIGGER IF EXISTS palette_update_trigger ON wms.palette;
CREATE TRIGGER palette_update_trigger
    AFTER UPDATE ON wms.palette
    FOR EACH ROW
    EXECUTE FUNCTION wms.palette_trigger();

DROP TRIGGER IF EXISTS palette_delete_trigger ON wms.palette;
CREATE TRIGGER palette_delete_trigger
    AFTER DELETE ON wms.palette
    FOR EACH ROW
    EXECUTE FUNCTION wms.palette_trigger();