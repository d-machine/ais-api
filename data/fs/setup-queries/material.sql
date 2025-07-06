--drop table if exists material;
--drop table if exists material_history;
--drop function if exists material_trigger;
--drop function if exists delete_material;
-- -- Create material table
CREATE TABLE IF NOT EXISTS wms.material (
    id SERIAL PRIMARY KEY,
    material_name VARCHAR(255) NOT NULL UNIQUE,
    brand_id INTEGER REFERENCES wms.item_brand(id),
    uom_rate_id INTEGER REFERENCES wms.uom(id),
    uom_pc_id INTEGER REFERENCES wms.uom(id),
    uom_package_id INTEGER REFERENCES wms.uom(id),
    description VARCHAR(255),
    is_active boolean NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);
-- -- Create temporal table for material
CREATE TABLE IF NOT EXISTS wms.material_history (
    history_id SERIAL PRIMARY KEY,
    material_id INTEGER,
    material_name VARCHAR(255) NOT NULL,
    brand_id INTEGER,
    uom_rate_id INTEGER,
    uom_pc_id INTEGER,                      
    uom_package_id INTEGER,
    description VARCHAR(255),
    operation VARCHAR(10),
    operation_at TIMESTAMP,     
    operation_by INTEGER REFERENCES administration.user(id)
);
-- -- Create trigger function for material
CREATE OR REPLACE FUNCTION wms.material_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN                    
        INSERT INTO wms.material_history (material_id, material_name, brand_id, uom_rate_id, uom_pc_id, uom_package_id, description, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.material_name, NEW.brand_id, NEW.uom_rate_id, NEW.uom_pc_id, NEW.uom_package_id, NEW.description, 'INSERT', NEW.lua, NEW.lub);
    ELSIF TG_OP = 'UPDATE' THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.material_history (material_id, material_name, brand_id, uom_rate_id, uom_pc_id, uom_package_id, description, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.material_name, NEW.brand_id, NEW.uom_rate_id, NEW.uom_pc_id, NEW.uom_package_id, NEW.description, 'DELETE', NEW.lua, NEW.lub);
        ELSE
            INSERT INTO wms.material_history (material_id, material_name, brand_id, uom_rate_id, uom_pc_id, uom_package_id, description, operation, operation_at,
            operation_by)
            VALUES (NEW.id, NEW.material_name, NEW.brand_id, NEW.uom_rate_id, NEW.uom_pc_id, NEW.uom_package_id, NEW.description, 'UPDATE', NEW.lua, NEW.lub);
        END IF;
    END IF;
    RETURN NEW;
END;            
$$ LANGUAGE plpgsql;
-- -- Create trigger for material
DROP TRIGGER IF EXISTS material_insert_trigger ON wms.material;
CREATE TRIGGER material_insert_trigger
    AFTER INSERT ON wms.material
    FOR EACH ROW
    EXECUTE FUNCTION wms.material_trigger();        
DROP TRIGGER IF EXISTS material_update_trigger ON wms.material;
CREATE TRIGGER material_update_trigger
    AFTER UPDATE ON wms.material
    FOR EACH ROW
    EXECUTE FUNCTION wms.material_trigger();
-- -- Create function to delete material
CREATE OR REPLACE FUNCTION wms.delete_material(material_id INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM wms.material WHERE id = material_id;
    DELETE FROM wms.material_history WHERE material_id = material_id;
END;
$$ LANGUAGE plpgsql;