create table wms.district (
  id serial primary key,
  name varchar(100) not null,
  description varchar(255),
  is_active boolean not null default false,
  lub integer references administration.user(id),
  lua TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE TABLE wms.district_history (
  history_id serial primary key,
  district_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(255),
  operation VARCHAR(10),
  operation_at TIMESTAMP,
  operation_by INTEGER REFERENCES administration.user(id)
);
---create trigger function for district
CREATE OR REPLACE FUNCTION wms.district_trigger()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO wms.district_history (district_id, name, description, operation, operation_at, operation_by)
    VALUES (NEW.id, NEW.name, NEW.description, 'INSERT', NEW.lua, NEW.lub);
  ELSIF (TG_OP = 'UPDATE') THEN
    INSERT INTO wms.district_history (district_id, name, description, operation, operation_at, operation_by)
    VALUES (NEW.id, NEW.name, NEW.description, 'UPDATE', NEW.lua, NEW.lub);
  ELSIF (TG_OP = 'DELETE') THEN
    INSERT INTO wms.district_history (district_id, name, description, operation, operation_at, operation_by)
    VALUES (OLD.id, OLD.name, OLD.description, 'DELETE', NEW.lua, NEW.lub);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---create trigger for district
DROP TRIGGER IF EXISTS district_trigger ON wms.district;
CREATE TRIGGER district_trigger
  AFTER INSERT OR UPDATE OR DELETE ON wms.district
  FOR EACH ROW
  EXECUTE FUNCTION wms.district_trigger();
