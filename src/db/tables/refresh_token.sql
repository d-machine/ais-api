-- Create refresh_token table
CREATE TABLE IF NOT EXISTS administration.refresh_token (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES administration.user(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_updated_by INTEGER NOT NULL REFERENCES administration.user(id)
);

-- Create refresh_token_history table for temporal functionality
CREATE TABLE IF NOT EXISTS administration.refresh_token_history (
    id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    token TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_updated_by INTEGER NOT NULL,
    operation VARCHAR(10) NOT NULL,
    operation_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    operation_by INTEGER NOT NULL REFERENCES administration.user(id)
);

-- Create trigger function for refresh_token history
CREATE OR REPLACE FUNCTION administration.refresh_token_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO administration.refresh_token_history (
            id, user_id, token, expires_at, last_updated_at, last_updated_by,
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.user_id, NEW.token, NEW.expires_at, NEW.last_updated_at, NEW.last_updated_by,
            TG_OP, CURRENT_TIMESTAMP, NEW.last_updated_by
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO administration.refresh_token_history (
            id, user_id, token, expires_at, last_updated_at, last_updated_by,
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.user_id, NEW.token, NEW.expires_at, NEW.last_updated_at, NEW.last_updated_by,
            TG_OP, CURRENT_TIMESTAMP, NEW.last_updated_by
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO administration.refresh_token_history (
            id, user_id, token, expires_at, last_updated_at, last_updated_by,
            operation, operation_at, operation_by
        )
        VALUES (
            OLD.id, OLD.user_id, OLD.token, OLD.expires_at, OLD.last_updated_at, OLD.last_updated_by,
            TG_OP, CURRENT_TIMESTAMP, OLD.last_updated_by
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for refresh_token
CREATE TRIGGER refresh_token_audit_insert
    AFTER INSERT ON administration.refresh_token
    FOR EACH ROW
    EXECUTE FUNCTION administration.refresh_token_audit();

CREATE TRIGGER refresh_token_audit_update
    AFTER UPDATE ON administration.refresh_token
    FOR EACH ROW
    EXECUTE FUNCTION administration.refresh_token_audit();

CREATE TRIGGER refresh_token_audit_delete
    AFTER DELETE ON administration.refresh_token
    FOR EACH ROW
    EXECUTE FUNCTION administration.refresh_token_audit(); 