-- Create the main table for Materials
CREATE TABLE IF NOT EXISTS wms.material (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    descr VARCHAR(255),
    brand_id INT REFERENCES wms.item_brand(id),
    uom_pc_id INT REFERENCES wms.uom(id),
    uom_package_id INT REFERENCES wms.uom(id),
    pc_in_package NUMERIC,
    is_active BOOLEAN NOT NULL DEFAULT true, -- Used for soft deletes
    lub INT REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create the history table to audit changes to material
CREATE TABLE IF NOT EXISTS wms.material_history (
    history_id SERIAL PRIMARY KEY,
    material_id INTEGER,
    name VARCHAR(255),
    descr VARCHAR(255),
    brand_id INT,
    uom_pc_id INT,
    uom_package_id INT,
    pc_in_package NUMERIC,
    is_active boolean NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INT REFERENCES administration.user(id)
);

-- Trigger function to log all INSERT and UPDATE operations
CREATE OR REPLACE FUNCTION wms.log_material_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.material_history (material_id, name, descr, brand_id, uom_pc_id, uom_package_id, pc_in_package, is_active, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.name, NEW.descr, NEW.brand_id, NEW.uom_pc_id, NEW.uom_package_id, NEW.pc_in_package, NEW.is_active, 'INSERT', NEW.lua, NEW.lub);

    ELSIF TG_OP = 'UPDATE' THEN
        -- If the record is being deactivated, log it as a 'DELETE' operation for clarity
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.material_history (material_id, name, descr, brand_id, uom_pc_id, uom_package_id, pc_in_package, is_active, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.name, NEW.descr, NEW.brand_id, NEW.uom_pc_id, NEW.uom_package_id, NEW.pc_in_package, NEW.is_active, 'DELETE', NEW.lua, NEW.lub);
        ELSE
            INSERT INTO wms.material_history (material_id, name, descr, brand_id, uom_pc_id, uom_package_id, pc_in_package, is_active, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.name, NEW.descr, NEW.brand_id, NEW.uom_pc_id, NEW.uom_package_id, NEW.pc_in_package, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Assign the trigger function to the material table
DROP TRIGGER IF EXISTS material_insert_trigger ON wms.material;
CREATE TRIGGER material_insert_trigger
    AFTER INSERT ON wms.material
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_material_changes();

DROP TRIGGER IF EXISTS material_update_trigger ON wms.material;
CREATE TRIGGER material_update_trigger
    AFTER UPDATE ON wms.material
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_material_changes();
