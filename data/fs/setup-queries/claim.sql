-- Drop existing objects
-- DROP TRIGGER IF EXISTS claim_insert_trigger ON administration.claim;
-- DROP TRIGGER IF EXISTS claim_update_trigger ON administration.claim;
-- DROP FUNCTION IF EXISTS administration.log_claim_changes();
-- DROP FUNCTION IF EXISTS administration.delete_claim(INTEGER, INTEGER);
-- DROP TABLE IF EXISTS administration.claim_history;
-- DROP TABLE IF EXISTS administration.claim;

-- Create table
CREATE TABLE IF NOT EXISTS administration.claim (
  id SERIAL PRIMARY KEY,
  role_id INTEGER NOT NULL REFERENCES administration.role(id),
  resource_id INTEGER NOT NULL REFERENCES administration.resource(id),
  access_level_id VARCHAR(255) NOT NULL,
  access_type_ids varchar(255) NOT NULL,
  is_active boolean not null default true,
  lub integer references administration.user(id),
  lua TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE (role_id, resource_id)
);

-- Create history table
CREATE TABLE IF NOT EXISTS administration.claim_history (
  history_id SERIAL PRIMARY KEY,
  claim_id INT,
  role_id INTEGER NOT NULL,
  resource_id INTEGER NOT NULL,
  access_level_id VARCHAR(255) NOT NULL,
  access_type_ids varchar(255) NOT NULL,
  operation VARCHAR(10),
  operation_at TIMESTAMP,
  operation_by int REFERENCES administration.user(id)
);

-- Create trigger function
CREATE OR REPLACE FUNCTION administration.log_claim_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO administration.claim_history (claim_id, role_id, resource_id, access_level_id, access_type_ids, operation, operation_at, operation_by)
        VALUES (NEW.id, NEW.role_id, NEW.resource_id, NEW.access_level_id, NEW.access_type_ids, 'INSERT', NEW.lua, NEW.lub);
    ELSIF TG_OP = 'UPDATE' THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO administration.claim_history (claim_id,role_id,resource_id,access_level_id,access_type_ids,operation,operation_at,operation_by)
            VALUES (NEW.id,NEW.role_id,NEW.resource_id,NEW.access_level_id,NEW.access_type_ids,'DELETE',NEW.lua,NEW.lub);
        ELSIF (OLD.is_active = false AND NEW.is_active = true) THEN
            INSERT INTO administration.claim_history (claim_id,role_id,resource_id,access_level_id,access_type_ids,operation,operation_at,operation_by)
            VALUES (NEW.id,NEW.role_id,NEW.resource_id,NEW.access_level_id,NEW.access_type_ids,'RECOVER',NEW.lua,NEW.lub);
        ELSE
            INSERT INTO administration.claim_history (claim_id,role_id,resource_id,access_level_id,access_type_ids,operation,operation_at,operation_by)
            VALUES (NEW.id,NEW.role_id,NEW.resource_id,NEW.access_level_id,NEW.access_type_ids,'UPDATE',NEW.lua,NEW.lub);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS claim_insert_trigger ON administration.claim;
CREATE TRIGGER claim_insert_trigger
    AFTER INSERT ON administration.claim
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_claim_changes();

DROP TRIGGER IF EXISTS claim_update_trigger ON administration.claim;
CREATE TRIGGER claim_update_trigger
    AFTER UPDATE ON administration.claim
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_claim_changes();
