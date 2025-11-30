-- Create address table (denormalized with state_id and country_id for performance)
CREATE TABLE IF NOT EXISTS wms.address (
    id SERIAL PRIMARY KEY,
    adr1 VARCHAR(255) NOT NULL,
    adr2 VARCHAR(255),
    adr3 VARCHAR(255),
    city_id INTEGER NOT NULL REFERENCES wms.city(id),
    district_id INTEGER NOT NULL REFERENCES wms.district(id),
    state_id INTEGER REFERENCES wms.state(id),
    country_id INTEGER REFERENCES wms.country(id),
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active boolean NOT NULL DEFAULT true
);

-- Create history table for address
DROP TABLE IF EXISTS wms.address_history;
CREATE TABLE IF NOT EXISTS wms.address_history (
    history_id SERIAL PRIMARY KEY,
    address_id INTEGER,
    adr1 VARCHAR(255),
    adr2 VARCHAR(255),
    adr3 VARCHAR(255),
    city_id INTEGER,
    district_id INTEGER,
    state_id INTEGER,
    country_id INTEGER,
    is_active boolean NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Create trigger function for address
DROP FUNCTION IF EXISTS wms.address_trigger();
CREATE OR REPLACE FUNCTION wms.address_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.address_history(
            address_id, adr1, adr2, adr3, city_id, district_id, state_id, country_id, is_active, operation, operation_at, operation_by
        ) VALUES (
            NEW.id, NEW.adr1, NEW.adr2, NEW.adr3, NEW.city_id, NEW.district_id, NEW.state_id, NEW.country_id, NEW.is_active, 'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.address_history(
                address_id, adr1, adr2, adr3, city_id, district_id, state_id, country_id, is_active, operation, operation_at, operation_by
            ) VALUES (
                NEW.id, NEW.adr1, NEW.adr2, NEW.adr3, NEW.city_id, NEW.district_id, NEW.state_id, NEW.country_id, NEW.is_active, 'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.address_history(
                address_id, adr1, adr2, adr3, city_id, district_id, state_id, country_id, is_active, operation, operation_at, operation_by
            ) VALUES (
                NEW.id, NEW.adr1, NEW.adr2, NEW.adr3, NEW.city_id, NEW.district_id, NEW.state_id, NEW.country_id, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for address
DROP TRIGGER IF EXISTS address_insert_trigger ON wms.address;
CREATE TRIGGER address_insert_trigger
    AFTER INSERT ON wms.address
    FOR EACH ROW
    EXECUTE FUNCTION wms.address_trigger();

DROP TRIGGER IF EXISTS address_update_trigger ON wms.address;
CREATE TRIGGER address_update_trigger
    AFTER UPDATE ON wms.address
    FOR EACH ROW
    EXECUTE FUNCTION wms.address_trigger();

DROP TRIGGER IF EXISTS address_delete_trigger ON wms.address;
CREATE TRIGGER address_delete_trigger
    AFTER DELETE ON wms.address
    FOR EACH ROW
    EXECUTE FUNCTION wms.address_trigger();
