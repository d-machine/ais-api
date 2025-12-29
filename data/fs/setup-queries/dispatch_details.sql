-- Create dispatch_details table
CREATE TABLE IF NOT EXISTS wms.dispatch_details (
    id SERIAL PRIMARY KEY,
    header_id INTEGER NOT NULL REFERENCES wms.dispatch_header(id),
    material_id INTEGER NOT NULL REFERENCES wms.material(id),
    picking_detail_id INTEGER NOT NULL REFERENCES wms.picking_list_details(id),
    qty DECIMAL(15,3) NOT NULL,
    uom_id INTEGER REFERENCES wms.uom(id),
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create temporal table for dispatch_details
CREATE TABLE IF NOT EXISTS wms.dispatch_details_history (
    history_id SERIAL PRIMARY KEY,
    detail_id INTEGER,
    header_id INTEGER,
    material_id INTEGER,
    picking_detail_id INTEGER,
    qty DECIMAL(15,3),
    uom_id INTEGER,
    is_active BOOLEAN,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);
