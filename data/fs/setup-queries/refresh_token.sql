-- Drop table if exists
-- DROP TABLE IF EXISTS administration.refresh_token;

-- Create refresh_token table
CREATE TABLE IF NOT EXISTS administration.refresh_token (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES administration.user(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    expires_at TIMESTAMP NOT NULL
);
