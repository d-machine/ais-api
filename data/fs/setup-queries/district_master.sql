CREATE TABLE wms.district_master (
  id serial PRIMARY KEY,
  name varchar(100) NOT NULL,
  descr VARCHAR(255),
  is_active boolean NOT NULL DEFAULT true,
  lub INTEGER REFERENCES administration.user(id),
  lua TIMESTAMP NOT NULL DEFAULT NOW()
  
);
CREATE TABLE wms.district_master_history (
  history_id serial PRIMARY KEY,
  district_id INTEGER REFERENCES wms.district_master(id),
  name varchar(100) NOT NULL,
  descr VARCHAR(255),
  operation VARCHAR(10),
  operation_at TIMESTAMP,
  operation_by INTEGER REFERENCES administration.user(id)
);
--- create trigger function for district----
CREATE OR REPLACE FUNCTION wms.district_master_trigger()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO wms.district_master_history (district_id, name, descr, operation, operation_at, operation_by)
    VALUES (NEW.id, NEW.name, NEW.descr, 'INSERT', NEW.lua, NEW.lub);
  ELSIF (TG_OP = 'UPDATE') THEN
    IF (OLD.is_active = true AND NEW.is_active = false) THEN
      INSERT INTO wms.district_master_history (district_id,name,descr,operation,operation_at,operation_by)
      VALUES (NEW.id,NEW.name,NEW.descr,'DELETE',NEW.lua,NEW.lub);
    ELSE
      INSERT INTO wms.district_master_history (district_id,name,descr,operation,operation_at,operation_by)
      VALUES (NEW.id,NEW.name,NEW.descr,'UPDATE',NEW.lua,NEW.lub);
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--- create trigger for district---
DROP TRIGGER IF EXISTS district_master_trigger ON wms.district_master;
CREATE TRIGGER district_master_trigger
  BEFORE INSERT OR UPDATE
  ON wms.district_master
  FOR EACH ROW
  EXECUTE PROCEDURE wms.district_master_trigger();
