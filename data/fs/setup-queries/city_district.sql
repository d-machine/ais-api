CREATE TABLE wms.city_district (
id serial PRIMARY KEY,
city_id INTEGER REFERENCES wms.city(id),
district_id INTEGER REFERENCES wms.district(id),
state_id INTEGER REFERENCES wms.state_master(id),
description VARCHAR(255),
is_active boolean NOT NULL DEFAULT true,
lub INTEGER REFERENCES administration.user(id),
lua TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE wms.city_district_history (
history_id serial PRIMARY KEY,
city_district_id INTEGER NOT NULL,
city_id INTEGER NOT NULL,
district_id INTEGER NOT NULL,
state_id INTEGER NOT NULL,
description VARCHAR(255),
operation VARCHAR(10),
operation_at TIMESTAMP,
operation_by INTEGER REFERENCES administration.user(id)
); 

---create trigger function for city_district---
CREATE OR REPLACE FUNCTION wms.city_district_trigger()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO wms.city_district_history (city_district_id, city_id, district_id, state_id, description, operation, operation_at, operation_by)
    VALUES (NEW.id, NEW.city_id, NEW.district_id, NEW.state_id, NEW.description, 'INSERT', NEW.lua, NEW.lub);
 ELSIF (TG_OP = 'UPDATE') THEN
  -- Check if is_active is being set to false (soft delete)
  IF (OLD.is_active = true AND NEW.is_active = false) THEN
    INSERT INTO wms.city_district_history (city_district_id,city_id,district_id,state_id,description,operation,operation_at,operation_by)
    VALUES (NEW.id,NEW.city_id,NEW.district_id,NEW.state_id,NEW.description,'DELETE',NEW.lua,NEW.lub);
  ELSE
    INSERT INTO wms.city_district_history (city_district_id,city_id,district_id,state_id,description,operation,operation_at,operation_by)
    VALUES (NEW.id,NEW.city_id,NEW.district_id,NEW.state_id,NEW.description,'UPDATE',NEW.lua,NEW.lub);
  END IF;

  ELSIF (TG_OP = 'DELETE') THEN
    INSERT INTO wms.city_district_history (city_district_id, city_id, district_id, state_id, description, operation, operation_at, operation_by)
    VALUES (OLD.id, OLD.city_id, OLD.district_id, OLD.state_id, OLD.description, 'DELETE', NEW.lua, NEW.lub);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---create trigger for city_district---
DROP TRIGGER IF EXISTS city_district_trigger ON wms.city_district;
CREATE TRIGGER city_district_trigger
BEFORE INSERT OR UPDATE OR DELETE ON wms.city_district
FOR EACH ROW
EXECUTE FUNCTION wms.city_district_trigger();
