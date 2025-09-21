-- Create item_category table
CREATE TABLE IF NOT EXISTS wms.item_category (
  id serial PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  descr VARCHAR(255),
  is_active boolean NOT NULL DEFAULT true,
  lub INTEGER REFERENCES administration.user(id),
  lua TIMESTAMP NOT NULL DEFAULT NOW()
);
-- Create temporal table for item_category
CREATE TABLE IF NOT EXISTS wms.item_category_history (
  history_id serial PRIMARY KEY,
  item_category_id INTEGER NOT NULL,
  name VARCHAR(255) NOT NULL,
  descr VARCHAR(255),
  is_active boolean NOT NULL,
  operation VARCHAR(10),
  operation_at TIMESTAMP,
  operation_by INTEGER REFERENCES administration.user(id)
);
-- Create trigger function for item_category
CREATE OR REPLACE FUNCTION wms.item_category_trigger()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO wms.item_category_history (item_category_id, name, descr, is_active, operation, operation_at, operation_by)
    VALUES (NEW.id, NEW.name, NEW.descr, NEW.is_active, 'INSERT', NEW.lua, NEW.lub);
  ELSIF (TG_OP = 'UPDATE') THEN
    -- Check if is_active is being set to false (soft delete)
    IF (OLD.is_active = true AND NEW.is_active = false) THEN
      INSERT INTO wms.item_category_history (item_category_id, name, descr, is_active, operation, operation_at, operation_by)
      VALUES (NEW.id, NEW.name, NEW.descr, NEW.is_active, 'DELETE', NEW.lua, NEW.lub);
    ELSE
      INSERT INTO wms.item_category_history (item_category_id, name, descr, is_active, operation, operation_at, operation_by)
      VALUES (NEW.id, NEW.name, NEW.descr, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub);
    END IF; 
  ELSIF (TG_OP = 'DELETE') THEN   
    INSERT INTO wms.item_category_history (item_category_id, name, descr, is_active, operation, operation_at, operation_by)
    VALUES (OLD.id, OLD.name, OLD.descr, OLD.is_active, 'DELETE', OLD.lua, OLD.lub);     
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Create trigger for item_category
DROP TRIGGER IF EXISTS item_category_insert_trigger ON wms.item_category;
CREATE TRIGGER item_category_insert_trigger
    BEFORE INSERT ON wms.item_category
    FOR EACH ROW
    EXECUTE FUNCTION wms.item_category_trigger();

DROP TRIGGER IF EXISTS item_category_update_trigger ON wms.item_category;
CREATE TRIGGER item_category_update_trigger
    BEFORE UPDATE ON wms.item_category
    FOR EACH ROW
    EXECUTE FUNCTION wms.item_category_trigger();

DROP TRIGGER IF EXISTS item_category_delete_trigger ON wms.item_category;
CREATE TRIGGER item_category_delete_trigger
    BEFORE DELETE ON wms.item_category
    FOR EACH ROW
    EXECUTE FUNCTION wms.item_category_trigger();