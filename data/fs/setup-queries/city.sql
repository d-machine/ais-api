CREATE TABLE wms.city (
  id serial PRIMARY KEY,
  name varchar(100) NOT NULL,
  description VARCHAR(255),
  is_active boolean NOT NULL DEFAULT true,
  lub INTEGER REFERENCES administration.user(id),
  lua TIMESTAMP NOT NULL DEFAULT NOW()
  
);
CREATE TABLE wms.city_history (
  history_id serial PRIMARY KEY,
    id INTEGER REFERENCES wms.city(id),
    name varchar(100) NOT NULL,
    description VARCHAR(255),

    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);
--- create trigger function for city----
CREATE OR REPLACE FUNCTION wms.city_trigger()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO wms.city_history (city_id, name, description, operation, operation_at, operation_by)
    VALUES (NEW.id, NEW.name, NEW.description, 'INSERT', NEW.lua, NEW.lub);
  ELSIF (TG_OP = 'UPDATE') THEN
    IF (OLD.is_active = true AND NEW.is_active = false) THEN
      INSERT INTO wms.city_history (city_id,name,description,operation,operation_at,operation_by)
      VALUES (NEW.id,NEW.name,NEW.description,'DELETE',NEW.lua,NEW.lub);
    ELSE
      INSERT INTO wms.city_history (city_id,name,description,operation,operation_at,operation_by)
      VALUES (NEW.id,NEW.name,NEW.description,'UPDATE',NEW.lua,NEW.lub);
    END IF;
  ELSIF (TG_OP = 'DELETE') THEN
    INSERT INTO wms.city_history (city_id, name, description, operation, operation_at, operation_by)
    VALUES (OLD.id, OLD.name, OLD.description, 'DELETE', NEW.lua, NEW.lub);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--- create trigger for city---
DROP TRIGGER IF EXISTS city_trigger ON wms.city;
CREATE TRIGGER city_trigger
  BEFORE INSERT OR UPDATE OR DELETE
  ON wms.city
  FOR EACH ROW
  EXECUTE PROCEDURE wms.city_trigger();
