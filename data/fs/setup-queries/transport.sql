-- Create transport table
CREATE TABLE IF NOT EXISTS wms.transport (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    descr VARCHAR(255),
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active boolean NOT NULL DEFAULT true
);

-- Create history table for transport
drop table if exists wms.transport_history;
CREATE TABLE IF NOT EXISTS wms.transport_history (
    history_id SERIAL PRIMARY KEY,
    transport_id INTEGER,
    name VARCHAR(255),
    descr VARCHAR(255),
    is_active boolean NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Create trigger function for transport
drop function if exists wms.transport_trigger();
CREATE OR REPLACE FUNCTION wms.transport_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.transport_history(
            transport_id, name, descr, is_active, operation, operation_at, operation_by
        ) VALUES (
            NEW.id, NEW.name, NEW.descr, NEW.is_active, 'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.transport_history(
                transport_id, name, descr, is_active, operation, operation_at, operation_by
            ) VALUES (
                NEW.id, NEW.name, NEW.descr, NEW.is_active, 'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.transport_history(
                transport_id, name, descr, is_active, operation, operation_at, operation_by
            ) VALUES (
                NEW.id, NEW.name, NEW.descr, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for transport
drop trigger if exists transport_insert_trigger on wms.transport;
CREATE TRIGGER transport_insert_trigger
    AFTER INSERT ON wms.transport
    FOR EACH ROW
    EXECUTE FUNCTION wms.transport_trigger();

drop trigger if exists transport_update_trigger on wms.transport;
CREATE TRIGGER transport_update_trigger
    AFTER UPDATE ON wms.transport
    FOR EACH ROW
    EXECUTE FUNCTION wms.transport_trigger();

drop trigger if exists transport_delete_trigger on wms.transport;
CREATE TRIGGER transport_delete_trigger
    AFTER DELETE ON wms.transport
    FOR EACH ROW
    EXECUTE FUNCTION wms.transport_trigger();
