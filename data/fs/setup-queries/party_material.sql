-- Drop old party_material tables if they exist
DROP TABLE IF EXISTS wms.party_material_history CASCADE;
DROP TABLE IF EXISTS wms.party_material CASCADE;

-- Create the main table for Party-Material pricing
CREATE TABLE IF NOT EXISTS wms.party_material (
    id SERIAL PRIMARY KEY,
    material_id INTEGER NOT NULL REFERENCES wms.material(id),
    party_id INTEGER NOT NULL REFERENCES wms.party(id),
    selling_rate DECIMAL(15,2) NOT NULL,
    date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    remarks VARCHAR(255),
    UNIQUE(material_id, party_id, date)
);

-- Create the history table to audit changes to party_material
CREATE TABLE IF NOT EXISTS wms.party_material_history (
    history_id SERIAL PRIMARY KEY,
    party_material_id INTEGER,
    material_id INTEGER,
    party_id INTEGER,
    selling_rate DECIMAL(15,2),
    date DATE,
    is_active BOOLEAN NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Trigger function to log all INSERT and UPDATE operations
DROP FUNCTION IF EXISTS wms.log_party_material_changes();
CREATE OR REPLACE FUNCTION wms.log_party_material_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.party_material_history (
            party_material_id, material_id, party_id, selling_rate, date, is_active,
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.material_id, NEW.party_id, NEW.selling_rate, NEW.date, NEW.is_active,
            'INSERT', NEW.lua, NEW.lub
        );

    ELSIF TG_OP = 'UPDATE' THEN
        -- If the record is being deactivated, log it as a 'DELETE' operation for clarity
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.party_material_history (
                party_material_id, material_id, party_id, selling_rate, date, is_active,
                operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.material_id, NEW.party_id, NEW.selling_rate, NEW.date, NEW.is_active,
                'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.party_material_history (
                party_material_id, material_id, party_id, selling_rate, date, is_active,
                operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.material_id, NEW.party_id, NEW.selling_rate, NEW.date, NEW.is_active,
                'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Assign the trigger function to the party_material table
DROP TRIGGER IF EXISTS party_material_insert_trigger ON wms.party_material;
CREATE TRIGGER party_material_insert_trigger
    AFTER INSERT ON wms.party_material
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_party_material_changes();

DROP TRIGGER IF EXISTS party_material_update_trigger ON wms.party_material;
CREATE TRIGGER party_material_update_trigger
    AFTER UPDATE ON wms.party_material
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_party_material_changes();
