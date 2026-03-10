-- Drop old party_contact_details tables if they exist
DROP TABLE IF EXISTS wms.party_contact_details_history CASCADE;
DROP TABLE IF EXISTS wms.party_contact_details CASCADE;

-- Create party contact details table
CREATE TABLE IF NOT EXISTS wms.party_contact_details (
    id SERIAL PRIMARY KEY,
    party_id INTEGER NOT NULL REFERENCES wms.party(id),
    name VARCHAR(100) NOT NULL,
    telephone VARCHAR(20),
    email VARCHAR(100),
    position VARCHAR(100),
    descr VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create history table
CREATE TABLE IF NOT EXISTS wms.party_contact_details_history (
    history_id SERIAL PRIMARY KEY,
    contact_id INTEGER,
    party_id INTEGER,
    name VARCHAR(100),
    telephone VARCHAR(20),
    email VARCHAR(100),
    position VARCHAR(100),
    descr VARCHAR(255),
    is_active BOOLEAN NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Trigger function
DROP FUNCTION IF EXISTS wms.log_party_contact_changes();
CREATE OR REPLACE FUNCTION wms.log_party_contact_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO wms.party_contact_details_history (
            contact_id, party_id, name, telephone, email, position, descr,
            is_active, operation, operation_at, operation_by
        ) VALUES (
            NEW.id, NEW.party_id, NEW.name, NEW.telephone, NEW.email, NEW.position, NEW.descr,
            NEW.is_active, 'INSERT', NEW.lua, NEW.lub
        );
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO wms.party_contact_details_history (
            contact_id, party_id, name, telephone, email, position, descr,
            is_active, operation, operation_at, operation_by
        ) VALUES (
            NEW.id, NEW.party_id, NEW.name, NEW.telephone, NEW.email, NEW.position, NEW.descr,
            NEW.is_active,
            CASE WHEN OLD.is_active = true AND NEW.is_active = false THEN 'DELETE' ELSE 'UPDATE' END,
            NEW.lua, NEW.lub
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS party_contact_insert_trigger ON wms.party_contact_details;
CREATE TRIGGER party_contact_insert_trigger
    AFTER INSERT ON wms.party_contact_details
    FOR EACH ROW EXECUTE FUNCTION wms.log_party_contact_changes();

DROP TRIGGER IF EXISTS party_contact_update_trigger ON wms.party_contact_details;
CREATE TRIGGER party_contact_update_trigger
    AFTER UPDATE ON wms.party_contact_details
    FOR EACH ROW EXECUTE FUNCTION wms.log_party_contact_changes();
