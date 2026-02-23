-- Drop old material_ean tables if they exist
DROP TABLE IF EXISTS wms.material_ean_history CASCADE;
DROP TABLE IF EXISTS wms.material_ean CASCADE;

-- Create the EAN sub-master table
CREATE TABLE IF NOT EXISTS wms.material_ean (
    id SERIAL PRIMARY KEY,
    material_id INTEGER NOT NULL REFERENCES wms.material(id),
    ean_code VARCHAR(100) NOT NULL,
    label VARCHAR(255),
    uom_pc_id INTEGER REFERENCES wms.uom(id),
    uom_package_id INTEGER REFERENCES wms.uom(id),
    mrp DECIMAL(15,2),
    selling_rate DECIMAL(15,2),
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create the history table to audit changes to material_ean
CREATE TABLE IF NOT EXISTS wms.material_ean_history (
    history_id SERIAL PRIMARY KEY,
    material_ean_id INTEGER,
    material_id INTEGER,
    ean_code VARCHAR(100),
    label VARCHAR(255),
    uom_pc_id INTEGER,
    uom_package_id INTEGER,
    mrp DECIMAL(15,2),
    selling_rate DECIMAL(15,2),
    is_active BOOLEAN NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Trigger function to log all INSERT and UPDATE operations
DROP FUNCTION IF EXISTS wms.log_material_ean_changes();
CREATE OR REPLACE FUNCTION wms.log_material_ean_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.material_ean_history (
            material_ean_id, material_id, ean_code, label, uom_pc_id, uom_package_id,
            mrp, selling_rate, is_active, operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.material_id, NEW.ean_code, NEW.label, NEW.uom_pc_id, NEW.uom_package_id,
            NEW.mrp, NEW.selling_rate, NEW.is_active, 'INSERT', NEW.lua, NEW.lub
        );

    ELSIF TG_OP = 'UPDATE' THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.material_ean_history (
                material_ean_id, material_id, ean_code, label, uom_pc_id, uom_package_id,
                mrp, selling_rate, is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.material_id, NEW.ean_code, NEW.label, NEW.uom_pc_id, NEW.uom_package_id,
                NEW.mrp, NEW.selling_rate, NEW.is_active, 'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.material_ean_history (
                material_ean_id, material_id, ean_code, label, uom_pc_id, uom_package_id,
                mrp, selling_rate, is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.material_id, NEW.ean_code, NEW.label, NEW.uom_pc_id, NEW.uom_package_id,
                NEW.mrp, NEW.selling_rate, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Assign the trigger function to the material_ean table
DROP TRIGGER IF EXISTS material_ean_insert_trigger ON wms.material_ean;
CREATE TRIGGER material_ean_insert_trigger
    AFTER INSERT ON wms.material_ean
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_material_ean_changes();

DROP TRIGGER IF EXISTS material_ean_update_trigger ON wms.material_ean;
CREATE TRIGGER material_ean_update_trigger
    AFTER UPDATE ON wms.material_ean
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_material_ean_changes();
