-- Create UOM Conversion table
CREATE TABLE IF NOT EXISTS wms.uom_conversion (
    id SERIAL PRIMARY KEY,
    uom_id_each INTEGER NOT NULL REFERENCES wms.uom(id),
    uom_id_case INTEGER NOT NULL REFERENCES wms.uom(id),
    no_of_pcs NUMERIC NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(uom_id_each, uom_id_case)
);

-- Create history table for UOM Conversion
CREATE TABLE IF NOT EXISTS wms.uom_conversion_history (
    history_id SERIAL PRIMARY KEY,
    uom_conversion_id INTEGER,
    uom_id_each INTEGER NOT NULL,
    uom_id_case INTEGER NOT NULL,
    no_of_pcs NUMERIC NOT NULL,
    is_active BOOLEAN NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Trigger function to log all INSERT and UPDATE operations
DROP FUNCTION IF EXISTS wms.log_uom_conversion_changes();
CREATE OR REPLACE FUNCTION wms.log_uom_conversion_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.uom_conversion_history (
            uom_conversion_id, uom_id_each, uom_id_case, no_of_pcs,
            is_active, operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.uom_id_each, NEW.uom_id_case, NEW.no_of_pcs,
            NEW.is_active, 'INSERT', NEW.lua, NEW.lub
        );

    ELSIF TG_OP = 'UPDATE' THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.uom_conversion_history (
                uom_conversion_id, uom_id_each, uom_id_case, no_of_pcs,
                is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.uom_id_each, NEW.uom_id_case, NEW.no_of_pcs,
                NEW.is_active, 'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.uom_conversion_history (
                uom_conversion_id, uom_id_each, uom_id_case, no_of_pcs,
                is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.uom_id_each, NEW.uom_id_case, NEW.no_of_pcs,
                NEW.is_active, 'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Assign trigger function to uom_conversion table
DROP TRIGGER IF EXISTS uom_conversion_insert_trigger ON wms.uom_conversion;
CREATE TRIGGER uom_conversion_insert_trigger
    AFTER INSERT ON wms.uom_conversion
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_uom_conversion_changes();

DROP TRIGGER IF EXISTS uom_conversion_update_trigger ON wms.uom_conversion;
CREATE TRIGGER uom_conversion_update_trigger
    AFTER UPDATE ON wms.uom_conversion
    FOR EACH ROW
    EXECUTE FUNCTION wms.log_uom_conversion_changes();
