CREATE TABLE wms.district (
  id serial PRIMARY KEY,
  name varchar(100) NOT NULL,
  code VARCHAR(3) NOT NULL UNIQUE,
  descr VARCHAR(255),
  is_active boolean NOT NULL DEFAULT true,
  lub INTEGER REFERENCES administration.user(id),
  lua TIMESTAMP NOT NULL DEFAULT NOW()
  
);
CREATE TABLE wms.district_history (
  history_id serial PRIMARY KEY,
  district_id INTEGER REFERENCES wms.district(id),
  name varchar(100) NOT NULL,
  code VARCHAR(3) NOT NULL,
  descr VARCHAR(255),
  is_active boolean NOT NULL,
  operation VARCHAR(10),
  operation_at TIMESTAMP,
  operation_by INTEGER REFERENCES administration.user(id)
);
--- create trigger function for district----
CREATE OR REPLACE FUNCTION wms.district_trigger()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO wms.district_history (district_id, name, code, descr, is_active, operation, operation_at, operation_by)
    VALUES (NEW.id, NEW.name, NEW.code, NEW.descr, NEW.is_active, 'INSERT', NEW.lua, NEW.lub);
  ELSIF (TG_OP = 'UPDATE') THEN
    IF (OLD.is_active = true AND NEW.is_active = false) THEN
      INSERT INTO wms.district_history (district_id, name, code, descr, is_active, operation, operation_at, operation_by)
      VALUES (NEW.id, NEW.name, NEW.code, NEW.descr, NEW.is_active, 'DELETE', NEW.lua, NEW.lub);
    ELSE
      INSERT INTO wms.district_history (district_id, name, code, descr, is_active, operation, operation_at, operation_by)
      VALUES (NEW.id, NEW.name, NEW.code, NEW.descr, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub);
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--- create trigger for district---
DROP TRIGGER IF EXISTS district_trigger ON wms.district;
CREATE TRIGGER district_trigger
  AFTER INSERT OR UPDATE
  ON wms.district
  FOR EACH ROW
  EXECUTE PROCEDURE wms.district_trigger();
