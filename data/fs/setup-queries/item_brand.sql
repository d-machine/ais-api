--drop table if exists item_brand;
--drop table if exists item_brand_history;
--drop function if exists item_brand_trigger;       
--drop function if exists delete_item_brand;

-- Create item_brand table
CREATE TABLE IF NOT EXISTS wms.item_brand (
    id SERIAL PRIMARY KEY,
    brand_name VARCHAR(255) NOT NULL UNIQUE,
    category_id INTEGER NOT NULL REFERENCES wms.item_category_master(id),
    descr VARCHAR(255),
    is_active boolean NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);
-- Create temporal table for item_brand
CREATE TABLE IF NOT EXISTS wms.item_brand_history (
    history_id SERIAL PRIMARY KEY,
    item_brand_id INTEGER,
    brand_name VARCHAR(255) NOT NULL,
    category_id INTEGER NOT NULL REFERENCES wms.item_category_master(id),
    descr VARCHAR(255),
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);      
-- Create trigger function for item_brand
CREATE OR REPLACE FUNCTION wms.item_brand_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.item_brand_history (item_brand_id, brand_name, category_id, descr, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.brand_name, NEW.category_id, NEW.descr, 'INSERT', NEW.lua, NEW.lub);
    ELSIF TG_OP = 'UPDATE' THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.item_brand_history (item_brand_id, brand_name, category_id, descr, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.brand_name, NEW.category_id, NEW.descr, 'DELETE', NEW.lua, NEW.lub);
        ELSE
            INSERT INTO wms.item_brand_history (item_brand_id, brand_name, category_id, descr, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.brand_name, NEW.category_id, NEW.descr, 'UPDATE', NEW.lua, NEW.lub);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;                

-- Create trigger for item_brand
DROP TRIGGER IF EXISTS item_brand_insert_trigger ON wms.item_brand;
CREATE TRIGGER item_brand_insert_trigger


    AFTER INSERT ON wms.item_brand
    FOR EACH ROW
    EXECUTE FUNCTION wms.item_brand_trigger();

DROP TRIGGER IF EXISTS item_brand_update_trigger ON wms.item_brand;
CREATE TRIGGER item_brand_update_trigger
    AFTER UPDATE ON wms.item_brand
    FOR EACH ROW
    EXECUTE FUNCTION wms.item_brand_trigger();  
-- Create function to delete item_brand
CREATE OR REPLACE FUNCTION wms.delete_item_brand(item_brand_id INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM wms.item_brand WHERE id = item_brand_id;
    DELETE FROM wms.item_brand_history WHERE item_brand_id = item_brand_id;
END;
$$ LANGUAGE plpgsql;