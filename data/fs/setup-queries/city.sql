CREATE TABLE wms.city (
  id serial PRIMARY KEY,
  name varchar(100) NOT NULL,
  code VARCHAR(3) NOT NULL UNIQUE,
  descr VARCHAR(255),
  is_active boolean NOT NULL DEFAULT true,
  lub INTEGER REFERENCES administration.user(id),
  lua TIMESTAMP NOT NULL DEFAULT NOW()
  
);
CREATE TABLE wms.city_history (
  history_id serial PRIMARY KEY,
  city_id INTEGER REFERENCES wms.city(id),
  name varchar(100) NOT NULL,
  code VARCHAR(3) NOT NULL,
  descr VARCHAR(255),
  is_active boolean NOT NULL,
  operation VARCHAR(10),
  operation_at TIMESTAMP,
  operation_by INTEGER REFERENCES administration.user(id)
);
--- create trigger function for city----
CREATE OR REPLACE FUNCTION wms.city_trigger()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO wms.city_history (city_id, name, code, descr, is_active, operation, operation_at, operation_by)
    VALUES (NEW.id, NEW.name,NEW.code, NEW.descr, NEW.is_active, 'INSERT', NEW.lua, NEW.lub);
  ELSIF (TG_OP = 'UPDATE') THEN
    IF (OLD.is_active = true AND NEW.is_active = false) THEN
      INSERT INTO wms.city_history (city_id, name, code, descr, is_active, operation, operation_at, operation_by)
      VALUES (NEW.id, NEW.name, NEW.code, NEW.descr, NEW.is_active, 'DELETE', NEW.lua, NEW.lub);
    ELSE
      INSERT INTO wms.city_history (city_id, name, code, descr, is_active, operation, operation_at, operation_by)
      VALUES (NEW.id, NEW.name, NEW.code, NEW.descr, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub);
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--- create trigger for city---
DROP TRIGGER IF EXISTS city_trigger ON wms.city;
CREATE TRIGGER city_trigger
  BEFORE INSERT OR UPDATE
  ON wms.city
  FOR EACH ROW
  EXECUTE PROCEDURE wms.city_trigger();
