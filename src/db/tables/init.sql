-- Create administration schema
CREATE SCHEMA IF NOT EXISTS administration;

-- Create access_level type
DO $$ BEGIN
    CREATE TYPE access_level AS ENUM (
    'OWN',
    'INFERIORS',
    'ALL'
);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create access_type type
DO $$ BEGIN
    CREATE TYPE access_type AS ENUM (
    'READ',
    'ADD',
    'UPDATE',
    'DELETE',
    'EXPORT'
);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
