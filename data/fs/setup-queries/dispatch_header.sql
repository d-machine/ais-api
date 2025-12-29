-- Create dispatch_header table
CREATE TABLE IF NOT EXISTS wms.dispatch_header (
    id SERIAL PRIMARY KEY,
    entry_no VARCHAR(50) UNIQUE NOT NULL,
    entry_dt DATE NOT NULL,
    party_id INTEGER NOT NULL REFERENCES wms.party(id),
    pl_ids TEXT, -- Comma separated Picking List IDs
    vehicle_no VARCHAR(50),
    driver_name VARCHAR(255),
    remarks VARCHAR(255),
    status VARCHAR(50) DEFAULT 'Draft', -- Draft, Dispatched
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create temporal table for dispatch_header
CREATE TABLE IF NOT EXISTS wms.dispatch_header_history (
    history_id SERIAL PRIMARY KEY,
    dispatch_id INTEGER,
    entry_no VARCHAR(50),
    entry_dt DATE,
    party_id INTEGER,
    pl_ids TEXT,
    vehicle_no VARCHAR(50),
    driver_name VARCHAR(255),
    status VARCHAR(50),
    is_active BOOLEAN,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);
