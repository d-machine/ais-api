--drop table if exists uom;
--drop table if exists uom_history;
--drop function if exists uom_trigger;
--drop function if exists delete_uom;
-- Create uom table
CREATE TABLE IF NOT EXISTS wms.uom (
    id SERIAL PRIMARY KEY,
    uom_name VARCHAR(255) NOT NULL UNIQUE,
    description VARCHAR(255),
    is_active boolean NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);
-- Create temporal table for uom
CREATE TABLE IF NOT EXISTS wms.uom_history (
    history_id SERIAL PRIMARY KEY,
    uom_id INTEGER,
    uom_name VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    operation VARCHAR(10),
    operation_at TIMESTAMP,     
    operation_by INTEGER REFERENCES administration.user(id)
);
-- Create trigger function for uom
CREATE OR REPLACE FUNCTION wms.uom_trigger()
RETURNS TRIGGER AS $$
BEGIN       
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.uom_history (uom_id, uom_name, description, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.uom_name, NEW.description, 'INSERT', NEW.lua, NEW.lub);
    ELSIF TG_OP = 'UPDATE' THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.uom_history (uom_id, uom_name, description, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.uom_name, NEW.description, 'DELETE', NEW.lua, NEW.lub);
        ELSE
            INSERT INTO wms.uom_history (uom_id, uom_name, description, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.uom_name, NEW.description, 'UPDATE', NEW.lua, NEW.lub);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Create trigger for uom
DROP TRIGGER IF EXISTS uom_insert_trigger ON wms.uom;
CREATE TRIGGER uom_insert_trigger
    AFTER INSERT ON wms.uom
    FOR EACH ROW
    EXECUTE FUNCTION wms.uom_trigger();     



DROP TRIGGER IF EXISTS uom_update_trigger ON wms.uom;
CREATE TRIGGER uom_update_trigger
    AFTER UPDATE ON wms.uom
    FOR EACH ROW
    EXECUTE FUNCTION wms.uom_trigger();     
-- Create function to delete uom
CREATE OR REPLACE FUNCTION wms.delete_uom(uom_id INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM wms.uom WHERE id = uom_id;
    DELETE FROM wms.uom_history WHERE uom_id = uom_id;
END;
$$ LANGUAGE plpgsql;    