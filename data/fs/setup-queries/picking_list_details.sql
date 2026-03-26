-- Create picking_list_details table
CREATE TABLE IF NOT EXISTS wms.picking_list_details (
    id SERIAL PRIMARY KEY,
    header_id INTEGER NOT NULL REFERENCES wms.picking_list_header(id),
    material_id INTEGER NOT NULL REFERENCES wms.material(id),
    rack_id INTEGER REFERENCES wms.rack(id), -- Suggested Rack
    expiry_dt DATE, -- Suggested Batch
    so_detail_ids TEXT NOT NULL DEFAULT '', -- Comma-separated list of SO detail IDs
    batch_no VARCHAR(100),
    qty DECIMAL(15,3) NOT NULL, -- Allocated Qty
    picked_qty DECIMAL(15,3) DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    remarks VARCHAR(255)
);

-- Create temporal table for picking_list_details
CREATE TABLE IF NOT EXISTS wms.picking_list_details_history (
    history_id SERIAL PRIMARY KEY,
    detail_id INTEGER,
    header_id INTEGER,
    material_id INTEGER,
    rack_id INTEGER,
    expiry_dt DATE,
    so_detail_ids TEXT,
    batch_no VARCHAR(100),
    qty DECIMAL(15,3),
    picked_qty DECIMAL(15,3),
    remarks VARCHAR(255),
    is_active BOOLEAN,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);


-- Create trigger function for picking_list_details
CREATE OR REPLACE FUNCTION wms.picking_list_details_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.picking_list_details_history(
            detail_id, header_id, material_id, rack_id, expiry_dt, so_detail_ids,
            batch_no, qty, picked_qty, remarks, is_active, operation, operation_at, operation_by
        )
        VALUES(
            NEW.id, NEW.header_id, NEW.material_id, NEW.rack_id, NEW.expiry_dt, NEW.so_detail_ids,
            NEW.batch_no, NEW.qty, NEW.picked_qty, NEW.remarks, NEW.is_active, 'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.picking_list_details_history(
                detail_id, header_id, material_id, rack_id, expiry_dt, so_detail_ids,
                batch_no, qty, picked_qty, remarks, is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.header_id, NEW.material_id, NEW.rack_id, NEW.expiry_dt, NEW.so_detail_ids,
                NEW.batch_no, NEW.qty, NEW.picked_qty, NEW.remarks, NEW.is_active, 'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.picking_list_details_history(
                detail_id, header_id, material_id, rack_id, expiry_dt, so_detail_ids,
                batch_no, qty, picked_qty, remarks, is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.header_id, NEW.material_id, NEW.rack_id, NEW.expiry_dt, NEW.so_detail_ids,
                NEW.batch_no, NEW.qty, NEW.picked_qty, NEW.remarks, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--Create trigger for picking_list_details
DROP TRIGGER IF EXISTS picking_list_details_insert_trigger ON wms.picking_list_details;
CREATE TRIGGER picking_list_details_insert_trigger
    AFTER INSERT ON wms.picking_list_details
    FOR EACH ROW
    EXECUTE FUNCTION wms.picking_list_details_trigger();

DROP TRIGGER IF EXISTS picking_list_details_update_trigger ON wms.picking_list_details;
CREATE TRIGGER picking_list_details_update_trigger
    AFTER UPDATE ON wms.picking_list_details
    FOR EACH ROW
    EXECUTE FUNCTION wms.picking_list_details_trigger();

DROP TRIGGER IF EXISTS picking_list_details_delete_trigger ON wms.picking_list_details;
CREATE TRIGGER picking_list_details_delete_trigger
    AFTER DELETE ON wms.picking_list_details
    FOR EACH ROW
    EXECUTE FUNCTION wms.picking_list_details_trigger();

