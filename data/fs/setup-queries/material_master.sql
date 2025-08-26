-- Create the main table for Materials
CREATE TABLE IF NOT EXISTS wms.material_master (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description VARCHAR(255),
    brand_id INT REFERENCES wms.item_brand(id),
    uom_pc_id INT REFERENCES wms.uom_master(id),
    uom_package_id INT REFERENCES wms.uom_master(id),
    pc_in_package NUMERIC,
    is_active BOOLEAN NOT NULL DEFAULT true, -- Used for soft deletes
    lub INT REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create the history table to audit changes to material_master
CREATE TABLE IF NOT EXISTS wms.material_master_history (
    history_id SERIAL PRIMARY KEY,
    material_master_id INTEGER,
    name VARCHAR(255),
    description VARCHAR(255),
    brand_id INT,
    uom_pc_id INT,
    uom_package_id INT,
    pc_in_package NUMERIC,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INT REFERENCES administration.user(id)
);

-- Trigger function to log all INSERT and UPDATE operations
CREATE OR REPLACE FUNCTION wms.log_material_master_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.material_master_history (material_master_id, name, description, brand_id, uom_pc_id, uom_package_id, pc_in_package, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.name, NEW.description, NEW.brand_id, NEW.uom_pc_id, NEW.uom_package_id, NEW.pc_in_package, 'INSERT', NEW.lua, NEW.lub);

    ELSIF TG_OP = 'UPDATE' THEN
        -- If the record is being deactivated, log it as a 'DELETE' operation for clarity
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.material_master_history (material_master_id, name, description, brand_id, uom_pc_id, uom_package_id, pc_in_package, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.name, NEW.description, NEW.brand_id, NEW.uom_pc_id, NEW.uom_package_id, NEW.pc_in_package, 'DELETE', NEW.lua, NEW.lub);
        ELSE
            INSERT INTO wms.material_master_history (material_master_id, name, description, brand_id, uom_pc_id, uom_package_id, pc_in_package, operation, operation_at, operation_by)
            VALUES (NEW.id, NEW.name, NEW.description, NEW.brand_id, NEW.uom_pc_id, NEW.uom_package_id, NEW.pc_in_package, 'UPDATE', NEW.lua, NEW.lub);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Assign the trigger function to the material_master table
DROP TRIGGER IF EXISTS material_master_insert_trigger ON wms.material_master;
CREATE TRIGGER material_master_insert_trigger
    AFTER INSERT ON wms.material_master
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_material_master_changes();

DROP TRIGGER IF EXISTS material_master_update_trigger ON wms.material_master;
CREATE TRIGGER material_master_update_trigger
    AFTER UPDATE ON wms.material_master
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_material_master_changes();

-- Custom function to perform a "soft delete" by setting is_active to false
CREATE OR REPLACE FUNCTION wms.delete_material_master(
    material_master_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    UPDATE wms.material_master
    SET is_active = false,
        lub = deleted_by_user_id,
        lua = NOW()
    WHERE id = material_master_id_to_delete;
END;
$$ LANGUAGE plpgsql;
