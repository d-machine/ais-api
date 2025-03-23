CREATE TABLE  wms.party_master (
  id SERIAL PRIMARY KEY,
  party_type VARCHAR(50),
  name VARCHAR(50),
  add1 VARCHAR(50),
  add2 VARCHAR(50),
  add3 VARCHAR(50),
  city VARCHAR(50),
  pincode VARCHAR(50),
  district VARCHAR(50),
  
  person_name VARCHAR(50),
  telephone VARCHAR(50),
  email VARCHAR(50),
  udate VARCHAR(50),
  salesman VARCHAR(50),
  pan_no VARCHAR(50),
  cr_limit NUMERIC, 
  cr_days INTEGER,
  gstno VARCHAR(50),
  

  aadhar_no VARCHAR(50),
  sales_head VARCHAR(50),
  director VARCHAR(50),
  manager VARCHAR(50),
  state_id INTEGER REFERENCES wms.state_master(id),
  country_id INTEGER REFERENCES wms.country_master(id),
  last_updated_by INTEGER REFERENCES administration.user(id),
  last_updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS wms.party_master_history (
    history_id SERIAL PRIMARY KEY,
    id INTEGER REFERENCES wms.party_master(id),
    party_type VARCHAR(50),
    name VARCHAR(50),
    add1 VARCHAR(50),
    add2 VARCHAR(50),
        add3 VARCHAR(50),
            city VARCHAR(50),
    pincode VARCHAR(50),
    district VARCHAR(50),
    state_id INTEGER REFERENCES wms.state_master(id),
    person_name VARCHAR(50),
    telephone VARCHAR(50),
    email VARCHAR(50),
    udate VARCHAR(50),
    salesman VARCHAR(50),
    pan_no VARCHAR(50),
    cr_limit NUMERIC, 
    cr_days INTEGER,
    gstno VARCHAR(50),
    country_id INTEGER REFERENCES wms.country_master(id),
    aadhar_no VARCHAR(50),
    sales_head VARCHAR(50),
    director VARCHAR(50),
    manager VARCHAR(50),
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);
-----create trigger function for party_master-----
CREATE OR REPLACE FUNCTION wms.party_master_trigger()
    RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO party_master_history (
            id,
            party_type,
            name,
            add1,
            add2,
            add3,
            city,
            pincode,
            district,
            state_id,
            person_name,
            telephone,
            email,
            udate,
            salesman,
            pan_no,
            cr_limit,
            cr_days,
            gstno,
            country_id,
            aadhar_no,
            sales_head,
            director,
            manager,
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id,
            NEW.party_type,
            NEW.name,
            NEW.add1,
            NEW.add2,
            NEW.add3,
            NEW.city,
            NEW.pincode,
            NEW.district,
            NEW.state_id,
            NEW.person_name,
            NEW.telephone,
            NEW.email,
            NEW.udate,
            NEW.salesman,
            NEW.pan_no,
            NEW.cr_limit,
            NEW.cr_days,
            NEW.gstno,
            NEW.country_id,
            NEW.aadhar_no,
            NEW.sales_head,
            NEW.director,
            NEW.manager,
            'INSERT', NEW.last_updated_at, NEW.last_updated_by
        );
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO party_master_history (
            id,
            party_type,
            name,
            add1,
            add2,
            add3,
            city,
            pincode,
            district,
            state_id,
            person_name,
            telephone,
            email,
            udate,
            salesman,
            pan_no,
            cr_limit,
            cr_days,
            gstno,
            country_id,
            aadhar_no,
            sales_head,
            director,
            manager,
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id,
            NEW.party_type,
            NEW.name,
            NEW.add1,
            NEW.add2,
            NEW.add3,
            NEW.city,
            NEW.pincode,
            NEW.district,
            NEW.state_id,
            NEW.person_name,
            NEW.telephone,
            NEW.email,
            NEW.udate,
            NEW.salesman,
            NEW.pan_no,
            NEW.cr_limit,
            NEW.cr_days,
            NEW.gstno,
            NEW.country_id,
            NEW.aadhar_no,
            NEW.sales_head,
            NEW.director,
            NEW.manager,
            'UPDATE', NEW.last_updated_at, NEW.last_updated_by
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- create trigger for party_master
DROP TRIGGER IF EXISTS party_master_trigger ON wms.party_master;
CREATE TRIGGER party_master_trigger
    AFTER INSERT OR UPDATE ON wms.party_master
    FOR EACH ROW
    EXECUTE FUNCTION wms.party_master_trigger();
