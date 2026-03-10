-- Drop old vendor tables if they exist
DROP TABLE IF EXISTS wms.vendor_history CASCADE;
DROP TABLE IF EXISTS wms.vendor CASCADE;

-- Create vendor table with normalized address fields
CREATE TABLE wms.vendor (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES wms.vendor_category(id),
    vendor_type VARCHAR(50),
    name VARCHAR(100) NOT NULL,

    -- Address fields (denormalized for performance)
    add1 VARCHAR(100),
    add2 VARCHAR(100),
    add3 VARCHAR(100),
    city_id INTEGER REFERENCES wms.city(id),
    district_id INTEGER REFERENCES wms.district(id),
    state_id INTEGER REFERENCES wms.state(id),
    country_id INTEGER REFERENCES wms.country(id),
    pincode VARCHAR(10),

    -- Business fields
    salesman VARCHAR(100),
    pan_no VARCHAR(20),
    cr_limit DECIMAL(15,2),
    cr_days INTEGER,
    gstno VARCHAR(20),
    aadhar_no VARCHAR(20),

    -- Audit fields
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create history table for vendor
CREATE TABLE wms.vendor_history (
    history_id SERIAL PRIMARY KEY,
    id INTEGER REFERENCES wms.vendor(id),
    category_id INTEGER,
    vendor_type VARCHAR(50),
    name VARCHAR(100),
    add1 VARCHAR(100),
    add2 VARCHAR(100),
    add3 VARCHAR(100),
    city_id INTEGER,
    district_id INTEGER,
    state_id INTEGER,
    country_id INTEGER,
    pincode VARCHAR(10),
    salesman VARCHAR(100),
    pan_no VARCHAR(20),
    cr_limit DECIMAL(15,2),
    cr_days INTEGER,
    gstno VARCHAR(20),
    aadhar_no VARCHAR(20),
    is_active BOOLEAN NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER
);

-- Create trigger function for vendor
DROP FUNCTION IF EXISTS wms.vendor_trigger();
CREATE OR REPLACE FUNCTION wms.vendor_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.vendor_history (
            id, category_id, vendor_type, name, add1, add2, add3,
            city_id, district_id, state_id, country_id, pincode,
            salesman, pan_no, cr_limit, cr_days, gstno, aadhar_no,
            is_active, operation, operation_at, operation_by
        ) VALUES (
            NEW.id, NEW.category_id, NEW.vendor_type, NEW.name, NEW.add1, NEW.add2, NEW.add3,
            NEW.city_id, NEW.district_id, NEW.state_id, NEW.country_id, NEW.pincode,
            NEW.salesman, NEW.pan_no, NEW.cr_limit, NEW.cr_days, NEW.gstno, NEW.aadhar_no,
            NEW.is_active, 'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO wms.vendor_history (
            id, category_id, vendor_type, name, add1, add2, add3,
            city_id, district_id, state_id, country_id, pincode,
            salesman, pan_no, cr_limit, cr_days, gstno, aadhar_no,
            is_active, operation, operation_at, operation_by
        ) VALUES (
            NEW.id, NEW.category_id, NEW.vendor_type, NEW.name, NEW.add1, NEW.add2, NEW.add3,
            NEW.city_id, NEW.district_id, NEW.state_id, NEW.country_id, NEW.pincode,
            NEW.salesman, NEW.pan_no, NEW.cr_limit, NEW.cr_days, NEW.gstno, NEW.aadhar_no,
            NEW.is_active,
            CASE WHEN OLD.is_active = true AND NEW.is_active = false THEN 'DELETE' ELSE 'UPDATE' END,
            NEW.lua, NEW.lub
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for vendor
DROP TRIGGER IF EXISTS vendor_insert_trigger ON wms.vendor;
CREATE TRIGGER vendor_insert_trigger
    AFTER INSERT ON wms.vendor
    FOR EACH ROW
    EXECUTE FUNCTION wms.vendor_trigger();

DROP TRIGGER IF EXISTS vendor_update_trigger ON wms.vendor;
CREATE TRIGGER vendor_update_trigger
    AFTER UPDATE ON wms.vendor
    FOR EACH ROW
    EXECUTE FUNCTION wms.vendor_trigger();
