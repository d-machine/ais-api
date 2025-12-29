-- Create picking_list_details table
CREATE TABLE IF NOT EXISTS wms.picking_list_details (
    id SERIAL PRIMARY KEY,
    header_id INTEGER NOT NULL REFERENCES wms.picking_list_header(id),
    so_detail_id INTEGER NOT NULL REFERENCES wms.sales_order_details(id), -- Added for precise tracking
    material_id INTEGER NOT NULL REFERENCES wms.material(id),
    rack_id INTEGER REFERENCES wms.rack(id), -- Suggested Rack
    expiry_dt DATE, -- Suggested Batch
    qty DECIMAL(15,3) NOT NULL, -- Allocated Qty
    picked_qty DECIMAL(15,3) DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    status VARCHAR(50) DEFAULT 'Pending' -- Pending, Picked
);

-- Create temporal table for picking_list_details
CREATE TABLE IF NOT EXISTS wms.picking_list_details_history (
    history_id SERIAL PRIMARY KEY,
    detail_id INTEGER,
    header_id INTEGER,
    so_detail_id INTEGER, -- Added
    material_id INTEGER,
    rack_id INTEGER,
    expiry_dt DATE,
    qty DECIMAL(15,3),
    picked_qty DECIMAL(15,3),
    status VARCHAR(50),
    is_active BOOLEAN,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);
