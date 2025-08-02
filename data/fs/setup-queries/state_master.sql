CREATE TABLE wms.state_master (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    descr VARCHAR(255),
    code VARCHAR(10) NOT NULL,
    country_id INTEGER REFERENCES wms.country_master(id),
    is_active boolean not null default true,
    lub int REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE wms.state_master_history (
    history_id SERIAL PRIMARY KEY,
    state_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    descr VARCHAR(255),
    code VARCHAR(10) NOT NULL,
    country_id INT NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);
-- create trigger function for state_master
CREATE OR REPLACE FUNCTION wms.state_master_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.state_master_history (state_id,name,descr,code,country_id,operation, operation_at, operation_by)
        VALUES (NEW.id,NEW.name,NEW.descr,NEW.code,NEW.country_id,'INSERT',NEW.lua,NEW.lub);
    ELSIF TG_OP = 'UPDATE' THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.state_master_history (state_id,name,country_id,code,descr,operation,operation_at,operation_by)
            VALUES (NEW.id,NEW.name,NEW.country_id,NEW.code,NEW.descr,'DELETE',NEW.lua,NEW.lub);
        ELSE
            INSERT INTO wms.state_master_history (state_id,name,country_id,code,descr,operation,operation_at,operation_by)
            VALUES (NEW.id,NEW.name,NEW.country_id,NEW.code,NEW.descr,'UPDATE',NEW.lua,NEW.lub);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- create trigger for state_master
DROP TRIGGER IF EXISTS state_master_trigger ON wms.state_master;
CREATE TRIGGER state_master_trigger
AFTER INSERT ON wms.state_master
FOR EACH ROW EXECUTE PROCEDURE wms.state_master_trigger();