-- Drop existing objects
-- DROP TRIGGER IF EXISTS hierarchy_closure_insert_trigger ON administration.hierarchy_closure;
-- DROP TRIGGER IF EXISTS hierarchy_closure_update_trigger ON administration.hierarchy_closure;
-- DROP FUNCTION IF EXISTS administration.log_hierarchy_closure_changes();
-- DROP FUNCTION IF EXISTS administration.delete_hierarchy_closure(INTEGER, INTEGER);
-- DROP TABLE IF EXISTS administration.hierarchy_closure_history;
-- DROP TABLE IF EXISTS administration.hierarchy_closure;

-- Create hierarchy_closure table
CREATE TABLE IF NOT EXISTS administration.hierarchy_closure (
    id SERIAL PRIMARY KEY,
    ancestor_id INTEGER REFERENCES administration.user(id),
    descendant_id INTEGER REFERENCES administration.user(id),
    depth INTEGER NOT NULL,
    last_updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_updated_by int REFERENCES administration.user(id),
    UNIQUE(ancestor_id, descendant_id)
);

-- Create history table
CREATE TABLE IF NOT EXISTS administration.hierarchy_closure_history (
    history_id SERIAL PRIMARY KEY,
    hierarchy_closure_id INT,
    ancestor_id INTEGER,
    descendant_id INTEGER,
    depth INTEGER,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by int REFERENCES administration.user(id)
);

-- Create trigger function
CREATE OR REPLACE FUNCTION administration.log_hierarchy_closure_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO administration.hierarchy_closure_history (
            hierarchy_closure_id, ancestor_id, descendant_id, depth,
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.ancestor_id, NEW.descendant_id, NEW.depth,
            'INSERT', NEW.last_updated_at, NEW.last_updated_by
        );
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO administration.hierarchy_closure_history (
            hierarchy_closure_id, ancestor_id, descendant_id, depth,
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

-- Create triggers
DROP TRIGGER IF EXISTS hierarchy_closure_insert_trigger ON administration.hierarchy_closure;
CREATE TRIGGER hierarchy_closure_insert_trigger
    AFTER INSERT ON administration.hierarchy_closure
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_hierarchy_closure_changes();

DROP TRIGGER IF EXISTS hierarchy_closure_update_trigger ON administration.hierarchy_closure;
CREATE TRIGGER hierarchy_closure_update_trigger
    AFTER UPDATE ON administration.hierarchy_closure
    FOR EACH ROW
    EXECUTE FUNCTION administration.log_hierarchy_closure_changes();

-- Custom delete function
CREATE OR REPLACE FUNCTION administration.delete_hierarchy_closure(
    hierarchy_closure_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    -- Insert into history before deletion
    INSERT INTO administration.hierarchy_closure_history (
        hierarchy_closure_id, ancestor_id, descendant_id, depth,
        operation, operation_at, operation_by
    )
    SELECT 
        id, ancestor_id, descendant_id, depth,
        'DELETE', NOW(), deleted_by_user_id
    FROM administration.hierarchy_closure
    WHERE id = hierarchy_closure_id_to_delete;

    -- Delete the hierarchy_closure
    DELETE FROM administration.hierarchy_closure WHERE id = hierarchy_closure_id_to_delete;
END;
$$ LANGUAGE plpgsql; 