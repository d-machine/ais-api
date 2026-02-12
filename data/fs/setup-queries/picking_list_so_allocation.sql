-- Create picking_list_so_allocation table
CREATE TABLE IF NOT EXISTS wms.picking_list_so_allocation (
    id SERIAL PRIMARY KEY,
    header_id INTEGER NOT NULL REFERENCES wms.picking_list_header(id),
    so_detail_id INTEGER NOT NULL REFERENCES wms.sales_order_details(id),
    material_id INTEGER NOT NULL REFERENCES wms.material(id),
    qty DECIMAL(15,3) NOT NULL DEFAULT 0,
    status VARCHAR(50) DEFAULT 'Pending',
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    remarks VARCHAR(255),
    UNIQUE(header_id, so_detail_id, material_id)
);

-- Create history table
CREATE TABLE IF NOT EXISTS wms.picking_list_so_allocation_history (
    history_id SERIAL PRIMARY KEY,
    allocation_id INTEGER,
    header_id INTEGER,
    so_detail_id INTEGER,
    material_id INTEGER,
    qty DECIMAL(15,3),
    status VARCHAR(50),
    is_active BOOLEAN,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Trigger function
CREATE OR REPLACE FUNCTION wms.picking_list_so_allocation_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.picking_list_so_allocation_history(
            allocation_id, header_id, so_detail_id, material_id, qty, status, is_active, operation, operation_at, operation_by
        ) VALUES (
            NEW.id, NEW.header_id, NEW.so_detail_id, NEW.material_id, NEW.qty, NEW.status, NEW.is_active, 'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO wms.picking_list_so_allocation_history(
            allocation_id, header_id, so_detail_id, material_id, qty, status, is_active, operation, operation_at, operation_by
        ) VALUES (
            NEW.id, NEW.header_id, NEW.so_detail_id, NEW.material_id, NEW.qty, NEW.status, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
DROP TRIGGER IF EXISTS picking_list_so_alloc_insert_trigger ON wms.picking_list_so_allocation;
CREATE TRIGGER picking_list_so_alloc_insert_trigger
    AFTER INSERT ON wms.picking_list_so_allocation
    FOR EACH ROW EXECUTE FUNCTION wms.picking_list_so_allocation_trigger();

DROP TRIGGER IF EXISTS picking_list_so_alloc_update_trigger ON wms.picking_list_so_allocation;
CREATE TRIGGER picking_list_so_alloc_update_trigger
    AFTER UPDATE ON wms.picking_list_so_allocation
    FOR EACH ROW EXECUTE FUNCTION wms.picking_list_so_allocation_trigger();
