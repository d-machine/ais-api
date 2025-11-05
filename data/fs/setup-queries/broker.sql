CREATE TABLE IF NOT EXISTS wms.broker (
  id SERIAL PRIMARY KEY,
  broker_type VARCHAR(50),
  name VARCHAR(50),
  add1 VARCHAR(50),
  add2 VARCHAR(50),
  add3 VARCHAR(50),
  city VARCHAR(50),
  pincode VARCHAR(50),
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
  city_district_id INTEGER REFERENCES wms.city_district(id),
  state_id INTEGER REFERENCES wms.state(id),
  country_id INTEGER REFERENCES wms.country(id),
  is_active boolean not null default true,
  lub INTEGER REFERENCES administration.user(id),
  lua TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS wms.broker_history (
    history_id SERIAL PRIMARY KEY,
    broker_id INTEGER NOT NULL,
    broker_type VARCHAR(50),
    name VARCHAR(50),
    add1 VARCHAR(50),
    add2 VARCHAR(50),
    add3 VARCHAR(50),
    city VARCHAR(50),
    pincode VARCHAR(50),
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
    city_district_id INTEGER NOT NULL,
    state_id INTEGER NOT NULL,
    country_id INTEGER NOT NULL,
    is_active boolean NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);
-----create trigger function for broker-----
CREATE OR REPLACE FUNCTION wms.broker_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.broker_history (
            broker_id,
            broker_type,
            name,
            add1,
            add2,
            add3,
            city,
            pincode,
            person_name,
            telephone,
            email,
            udate,
            salesman,
            pan_no,
            cr_limit,
            cr_days,
            gstno,
            aadhar_no,
            sales_head,
            director,
            manager,
            city_district_id,
            state_id,
            country_id,
            is_active,
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id,
            NEW.broker_type,
            NEW.name,
            NEW.add1,
            NEW.add2,
            NEW.add3,
            NEW.city,
            NEW.pincode,
            NEW.person_name,
            NEW.telephone,
            NEW.email,
            NEW.udate,
            NEW.salesman,
            NEW.pan_no,
            NEW.cr_limit,
            NEW.cr_days,
            NEW.gstno,
            NEW.aadhar_no,
            NEW.sales_head,
            NEW.director,
            NEW.manager,
            NEW.city_district_id,
            NEW.state_id,
            NEW.country_id,
            NEW.is_active,
            'INSERT', NEW.lua, NEW.lub
        );
    ELSIF TG_OP = 'UPDATE' THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.broker_history (
                broker_id,
                broker_type,
                name,
                add1,
                add2,
                add3,
                city,
                pincode,
                person_name,
                telephone,
                email,
                udate,
                salesman,
                pan_no,
                cr_limit,
                cr_days,
                gstno,
                aadhar_no,
                sales_head,
                director,
                manager,
                city_district_id,
                state_id,
                country_id,
                is_active,
                operation,operation_at,operation_by
            )
            VALUES (
                NEW.id,
                NEW.broker_type,
                NEW.name,
                NEW.add1,
                NEW.add2,
                NEW.add3,
                NEW.city,
                NEW.pincode,
                NEW.person_name,
                NEW.telephone,
                NEW.email,
                NEW.udate,
                NEW.salesman,
                NEW.pan_no,
                NEW.cr_limit,
                NEW.cr_days,
                NEW.gstno,
                NEW.aadhar_no,
                NEW.sales_head,
                NEW.director,
                NEW.manager,
                NEW.city_district_id,
                NEW.state_id,
                NEW.country_id,
                NEW.is_active,
                'DELETE',NEW.lua,NEW.lub
            );
        ELSE
            INSERT INTO wms.broker_history (
                broker_id,
                broker_type,
                name,
                add1,
                add2,
                add3,
                city,
                pincode,
                person_name,
                telephone,
                email,
                udate,
                salesman,
                pan_no,
                cr_limit,
                cr_days,
                gstno,
                aadhar_no,
                sales_head,
                director,
                manager,
                city_district_id,
                state_id,
                country_id,
                is_active,
                operation,operation_at,operation_by
            )
            VALUES (
                NEW.id,
                NEW.broker_type,
                NEW.name,
                NEW.add1,
                NEW.add2,
                NEW.add3,
                NEW.city,
                NEW.pincode,
                NEW.person_name,
                NEW.telephone,
                NEW.email,
                NEW.udate,
                NEW.salesman,
                NEW.pan_no,
                NEW.cr_limit,
                NEW.cr_days,
                NEW.gstno,
                NEW.aadhar_no,
                NEW.sales_head,
                NEW.director,
                NEW.manager,
                NEW.city_district_id,
                NEW.state_id,
                NEW.country_id,
                NEW.is_active,
                'UPDATE',NEW.lua,NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- create trigger for broker
DROP TRIGGER IF EXISTS broker_insert_trigger ON wms.broker;
CREATE TRIGGER broker_insert_trigger
AFTER INSERT ON wms.broker
FOR EACH ROW
EXECUTE FUNCTION wms.broker_trigger();

DROP TRIGGER IF EXISTS broker_update_trigger ON wms.broker;
CREATE TRIGGER broker_update_trigger
AFTER UPDATE ON wms.broker
FOR EACH ROW
EXECUTE FUNCTION wms.broker_trigger();  
-- Create function to delete broker
DROP TRIGGER IF EXISTS broker_delete_trigger ON wms.broker;
CREATE TRIGGER broker_delete_trigger
AFTER DELETE ON wms.broker
FOR EACH ROW
EXECUTE FUNCTION wms.broker_trigger();
