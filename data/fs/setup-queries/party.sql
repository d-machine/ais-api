-- Drop old party tables
DROP TABLE IF EXISTS wms.party_history CASCADE;
DROP TABLE IF EXISTS wms.party CASCADE;

-- Create party table with normalized address fields
CREATE TABLE wms.party (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES wms.party_category(id),
    party_type VARCHAR(50),
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
    
    -- Contact fields
    person_name VARCHAR(100),
    telephone VARCHAR(20),
    email VARCHAR(100),
    
    -- Business fields
    salesman VARCHAR(100),
    pan_no VARCHAR(20),
    cr_limit DECIMAL(15,2),
    cr_days INTEGER,
    gstno VARCHAR(20),
    aadhar_no VARCHAR(20),
    sales_head VARCHAR(100),
    director VARCHAR(100),
    manager VARCHAR(100),
    
    -- Audit fields
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create history table for party
CREATE TABLE wms.party_history (
    history_id SERIAL PRIMARY KEY,
    id INTEGER REFERENCES wms.party(id),
    category_id INTEGER,
    party_type VARCHAR(50),
    name VARCHAR(100),
    add1 VARCHAR(100),
    add2 VARCHAR(100),
    add3 VARCHAR(100),
    city_id INTEGER,
    district_id INTEGER,
    state_id INTEGER,
    country_id INTEGER,
    pincode VARCHAR(10),
    person_name VARCHAR(100),
    telephone VARCHAR(20),
    email VARCHAR(100),
    salesman VARCHAR(100),
    pan_no VARCHAR(20),
    cr_limit DECIMAL(15,2),
    cr_days INTEGER,
    gstno VARCHAR(20),
    aadhar_no VARCHAR(20),
    sales_head VARCHAR(100),
    director VARCHAR(100),
    manager VARCHAR(100),
    is_active BOOLEAN NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER
);

-- Create trigger function for party
DROP FUNCTION IF EXISTS wms.party_trigger();
CREATE OR REPLACE FUNCTION wms.party_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.party_history (
            id, category_id, party_type, name, add1, add2, add3,
            city_id, district_id, state_id, country_id, pincode,
            person_name, telephone, email, salesman, pan_no,
            cr_limit, cr_days, gstno, aadhar_no,
            sales_head, director, manager, is_active,
            operation, operation_at, operation_by
        ) VALUES (
            NEW.id, NEW.category_id, NEW.party_type, NEW.name, NEW.add1, NEW.add2, NEW.add3,
            NEW.city_id, NEW.district_id, NEW.state_id, NEW.country_id, NEW.pincode,
            NEW.person_name, NEW.telephone, NEW.email, NEW.salesman, NEW.pan_no,
            NEW.cr_limit, NEW.cr_days, NEW.gstno, NEW.aadhar_no,
            NEW.sales_head, NEW.director, NEW.manager, NEW.is_active,
            'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO wms.party_history (
            id, category_id, party_type, name, add1, add2, add3,
            city_id, district_id, state_id, country_id, pincode,
            person_name, telephone, email, salesman, pan_no,
            cr_limit, cr_days, gstno, aadhar_no,
            sales_head, director, manager, is_active,
            operation, operation_at, operation_by
        ) VALUES (
            NEW.id, NEW.category_id, NEW.party_type, NEW.name, NEW.add1, NEW.add2, NEW.add3,
            NEW.city_id, NEW.district_id, NEW.state_id, NEW.country_id, NEW.pincode,
            NEW.person_name, NEW.telephone, NEW.email, NEW.salesman, NEW.pan_no,
            NEW.cr_limit, NEW.cr_days, NEW.gstno, NEW.aadhar_no,
            NEW.sales_head, NEW.director, NEW.manager, NEW.is_active,
            CASE WHEN OLD.is_active = true AND NEW.is_active = false THEN 'DELETE' ELSE 'UPDATE' END,
            NEW.lua, NEW.lub
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for party
DROP TRIGGER IF EXISTS party_insert_trigger ON wms.party;
CREATE TRIGGER party_insert_trigger
    AFTER INSERT ON wms.party
    FOR EACH ROW
    EXECUTE FUNCTION wms.party_trigger();

DROP TRIGGER IF EXISTS party_update_trigger ON wms.party;
CREATE TRIGGER party_update_trigger
    AFTER UPDATE ON wms.party
    FOR EACH ROW
    EXECUTE FUNCTION wms.party_trigger();
