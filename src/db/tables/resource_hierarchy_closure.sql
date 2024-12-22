-- Drop table if exists
-- DROP TABLE IF EXISTS administration.resource_hierarchy_closure;
-- DROP TABLE IF EXISTS administration.resource_hierarchy_closure_history;
-- DROP FUNCTION IF EXISTS administration.resource_hierarchy_closure_trigger;
-- DROP FUNCTION IF EXISTS administration.delete_resource_hierarchy_closure;

-- Create resource_hierarchy_closure table
CREATE TABLE IF NOT EXISTS administration.resource_hierarchy_closure (
    id SERIAL PRIMARY KEY,
    ancestor_id INTEGER NOT NULL REFERENCES administration.resource(id),
    descendant_id INTEGER NOT NULL REFERENCES administration.resource(id),
    depth INTEGER NOT NULL,
    last_updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_updated_by INTEGER NOT NULL REFERENCES administration.user(id),
    CONSTRAINT resource_hierarchy_closure_unique UNIQUE (ancestor_id, descendant_id)
);

-- Create temporal table for resource_hierarchy_closure
CREATE TABLE IF NOT EXISTS administration.resource_hierarchy_closure_history (
    history_id SERIAL PRIMARY KEY,
    resource_hierarchy_closure_id INTEGER,
    ancestor_id INTEGER NOT NULL,
    descendant_id INTEGER NOT NULL,
    depth INTEGER NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Create trigger function for resource_hierarchy_closure
CREATE OR REPLACE FUNCTION administration.resource_hierarchy_closure_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO administration.resource_hierarchy_closure_history (
            resource_hierarchy_closure_id, ancestor_id, descendant_id, depth,
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.ancestor_id, NEW.descendant_id, NEW.depth,
            'INSERT', NEW.last_updated_at, NEW.last_updated_by
        );
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO administration.resource_hierarchy_closure_history (
            resource_hierarchy_closure_id, ancestor_id, descendant_id, depth,
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.ancestor_id, NEW.descendant_id, NEW.depth,
            'UPDATE', NEW.last_updated_at, NEW.last_updated_by
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for resource_hierarchy_closure
DROP TRIGGER IF EXISTS resource_hierarchy_closure_insert_trigger ON administration.resource_hierarchy_closure;
CREATE TRIGGER resource_hierarchy_closure_insert_trigger
    AFTER INSERT ON administration.resource_hierarchy_closure
    FOR EACH ROW
    EXECUTE FUNCTION administration.resource_hierarchy_closure_trigger();

DROP TRIGGER IF EXISTS resource_hierarchy_closure_update_trigger ON administration.resource_hierarchy_closure;
CREATE TRIGGER resource_hierarchy_closure_update_trigger
    AFTER UPDATE ON administration.resource_hierarchy_closure
    FOR EACH ROW
    EXECUTE FUNCTION administration.resource_hierarchy_closure_trigger();

-- Create view for current resource_hierarchy_closure
CREATE OR REPLACE VIEW administration.resource_hierarchy_closure_current AS
SELECT rhc.id, rhc.ancestor_id, rhc.descendant_id, rhc.depth, rhc.last_updated_at, rhc.last_updated_by
FROM administration.resource_hierarchy_closure rhc;

-- Function to delete resource_hierarchy_closure
CREATE OR REPLACE FUNCTION administration.delete_resource_hierarchy_closure(
    resource_hierarchy_closure_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    -- Insert into history before deletion
    INSERT INTO administration.resource_hierarchy_closure_history (
        resource_hierarchy_closure_id, ancestor_id, descendant_id, depth,
        operation, operation_at, operation_by
    )
    SELECT 
        id, ancestor_id, descendant_id, depth,
        'DELETE', NOW(), deleted_by_user_id
    FROM administration.resource_hierarchy_closure
    WHERE id = resource_hierarchy_closure_id_to_delete;

    -- Delete the resource_hierarchy_closure
    DELETE FROM administration.resource_hierarchy_closure 
    WHERE id = resource_hierarchy_closure_id_to_delete;
END;
$$ LANGUAGE plpgsql; 