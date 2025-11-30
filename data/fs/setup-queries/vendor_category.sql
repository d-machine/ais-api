-- Create vendor_category table
CREATE TABLE IF NOT EXISTS wms.vendor_category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    discount_percentage NUMERIC(5,2) DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create history table for vendor_category
DROP TABLE IF EXISTS wms.vendor_category_history;
CREATE TABLE IF NOT EXISTS wms.vendor_category_history (
    history_id SERIAL PRIMARY KEY,
    id INTEGER REFERENCES wms.vendor_category(id),
    name VARCHAR(100) NOT NULL,
    discount_percentage NUMERIC(5,2),
    is_active BOOLEAN NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Create trigger function for vendor_category
DROP FUNCTION IF EXISTS wms.vendor_category_trigger();
CREATE OR REPLACE FUNCTION wms.vendor_category_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.vendor_category_history (
            id, name, discount_percentage, is_active,
            operation, operation_at, operation_by
        ) VALUES (
            NEW.id, NEW.name, NEW.discount_percentage, NEW.is_active,
            'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO wms.vendor_category_history (
            id, name, discount_percentage, is_active,
            operation, operation_at, operation_by
        ) VALUES (
            NEW.id, NEW.name, NEW.discount_percentage, NEW.is_active,
            CASE WHEN OLD.is_active = true AND NEW.is_active = false THEN 'DELETE' ELSE 'UPDATE' END,
            NEW.lua, NEW.lub
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for vendor_category
DROP TRIGGER IF EXISTS vendor_category_insert_trigger ON wms.vendor_category;
CREATE TRIGGER vendor_category_insert_trigger
    AFTER INSERT ON wms.vendor_category
    FOR EACH ROW
    EXECUTE FUNCTION wms.vendor_category_trigger();

DROP TRIGGER IF EXISTS vendor_category_update_trigger ON wms.vendor_category;
CREATE TRIGGER vendor_category_update_trigger
    AFTER UPDATE ON wms.vendor_category
    FOR EACH ROW
    EXECUTE FUNCTION wms.vendor_category_trigger();
