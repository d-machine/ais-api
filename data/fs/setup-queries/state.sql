-- Rename table and related objects from state to state

-- Create table for state
CREATE TABLE wms.state (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    descr VARCHAR(255),
    code INTEGER NOT NULL,
    state_type VARCHAR(5) NOT NULL DEFAULT 'STATE' CHECK (state_type IN ('STATE', 'UT')),
    country_id INTEGER REFERENCES wms.country(id),
    is_active boolean not null default true,
    lub int REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create temporal table for state
CREATE TABLE wms.state_history (
    history_id SERIAL PRIMARY KEY,
    state_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    descr VARCHAR(255),
    code INTEGER NOT NULL,
    state_type VARCHAR(5),
    country_id INT NOT NULL,
    is_active boolean NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- create trigger function for state
CREATE OR REPLACE FUNCTION wms.state_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.state_history (state_id, name, descr, code, state_type, country_id, is_active, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.name, NEW.descr, NEW.code, NEW.state_type, NEW.country_id, NEW.is_active, 'INSERT', NEW.lua, NEW.lub);
    ELSIF TG_OP = 'UPDATE' THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.state_history (state_id, name, country_id, code, state_type, descr, is_active, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.name, NEW.country_id, NEW.code, NEW.state_type, NEW.descr, NEW.is_active, 'DELETE', NEW.lua, NEW.lub);
        ELSE
            INSERT INTO wms.state_history (state_id, name, country_id, code, state_type, descr, is_active, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.name, NEW.country_id, NEW.code, NEW.state_type, NEW.descr, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- create trigger for state
DROP TRIGGER IF EXISTS state_trigger ON wms.state;
CREATE TRIGGER state_trigger
AFTER INSERT ON wms.state
FOR EACH ROW EXECUTE PROCEDURE wms.state_trigger();
