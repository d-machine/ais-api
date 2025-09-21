-- Create address table
CREATE TABLE IF NOT EXISTS wms.address (
    id SERIAL PRIMARY KEY,
    adr1 VARCHAR(255) NOT NULL,
    adr2 VARCHAR(255),
    adr3 VARCHAR(255),
    country_id INTEGER NOT NULL REFERENCES wms.country(id),
    state_id INTEGER NOT NULL REFERENCES wms.state(id),
    city_district_id INTEGER NOT NULL REFERENCES wms.city_district(id),
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active boolean NOT NULL DEFAULT true
);

-- Create history table for address
drop table if exists wms.address_history;
CREATE TABLE IF NOT EXISTS wms.address_history (
    history_id SERIAL PRIMARY KEY,
    address_id INTEGER,
    adr1 VARCHAR(255),
    adr2 VARCHAR(255),
    adr3 VARCHAR(255),
    country_id INTEGER,
    state_id INTEGER,
    city_district_id INTEGER,
    is_active boolean NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Create trigger function for address
drop function if exists wms.address_trigger();
CREATE OR REPLACE FUNCTION wms.address_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.address_history(
            address_id, adr1, adr2, adr3, country_id, state_id, city_district_id, is_active, operation, operation_at, operation_by
        ) VALUES (
            NEW.id, NEW.adr1, NEW.adr2, NEW.adr3, NEW.country_id, NEW.state_id, NEW.city_district_id, NEW.is_active, 'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.address_history(
                address_id, adr1, adr2, adr3, country_id, state_id, city_district_id, is_active, operation, operation_at, operation_by
            ) VALUES (
                NEW.id, NEW.adr1, NEW.adr2, NEW.adr3, NEW.country_id, NEW.state_id, NEW.city_district_id, NEW.is_active, 'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.address_history(
                address_id, adr1, adr2, adr3, country_id, state_id, city_district_id, is_active, operation, operation_at, operation_by
            ) VALUES (
                NEW.id, NEW.adr1, NEW.adr2, NEW.adr3, NEW.country_id, NEW.state_id, NEW.city_district_id, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for address
drop trigger if exists address_insert_trigger on wms.address;
CREATE TRIGGER address_insert_trigger
    AFTER INSERT ON wms.address
    FOR EACH ROW
    EXECUTE FUNCTION wms.address_trigger();

drop trigger if exists address_update_trigger on wms.address;
CREATE TRIGGER address_update_trigger
    AFTER UPDATE ON wms.address
    FOR EACH ROW
    EXECUTE FUNCTION wms.address_trigger();

drop trigger if exists address_delete_trigger on wms.address;
CREATE TRIGGER address_delete_trigger
    AFTER DELETE ON wms.address
    FOR EACH ROW
    EXECUTE FUNCTION wms.address_trigger();
