-- Drop old material tables if they exist
DROP TABLE IF EXISTS wms.material_history CASCADE;
DROP TABLE IF EXISTS wms.material CASCADE;

-- Create the main table for Materials
CREATE TABLE IF NOT EXISTS wms.material (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    descr VARCHAR(255),
    category_id INTEGER REFERENCES wms.item_category(id),
    brand_id INTEGER REFERENCES wms.item_brand(id),
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create the history table to audit changes to material
CREATE TABLE IF NOT EXISTS wms.material_history (
    history_id SERIAL PRIMARY KEY,
    material_id INTEGER,
    name VARCHAR(255),
    descr VARCHAR(255),
    category_id INTEGER,
    brand_id INTEGER,
    is_active BOOLEAN NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Trigger function to log all INSERT and UPDATE operations
DROP FUNCTION IF EXISTS wms.log_material_changes();
CREATE OR REPLACE FUNCTION wms.log_material_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.material_history (
            material_id, name, descr, category_id, brand_id,
            is_active, operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.name, NEW.descr, NEW.category_id, NEW.brand_id,
            NEW.is_active, 'INSERT', NEW.lua, NEW.lub
        );

    ELSIF TG_OP = 'UPDATE' THEN
        -- If the record is being deactivated, log it as a 'DELETE' operation for clarity
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.material_history (
                material_id, name, descr, category_id, brand_id,
                is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.name, NEW.descr, NEW.category_id, NEW.brand_id,
                NEW.is_active, 'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.material_history (
                material_id, name, descr, category_id, brand_id,
                is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.name, NEW.descr, NEW.category_id, NEW.brand_id,
                NEW.is_active, 'UPDATE', NEW.lua, NEW.lub
            );
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
