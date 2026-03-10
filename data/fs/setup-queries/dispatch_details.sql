-- Create dispatch_details table
CREATE TABLE IF NOT EXISTS wms.dispatch_details (
    id SERIAL PRIMARY KEY,
    header_id INTEGER NOT NULL REFERENCES wms.dispatch_header(id),
    material_id INTEGER NOT NULL REFERENCES wms.material(id),
    picking_detail_id INTEGER NOT NULL REFERENCES wms.picking_list_so_allocation(id),
    qty DECIMAL(15,3) NOT NULL,
    uom_id INTEGER REFERENCES wms.uom(id),
    hsn_id INTEGER REFERENCES wms.hsn(id),
    cgst DECIMAL(5,2) NOT NULL DEFAULT 0,
    sgst DECIMAL(5,2) NOT NULL DEFAULT 0,
    igst DECIMAL(5,2) NOT NULL DEFAULT 0,
    utgst DECIMAL(5,2) NOT NULL DEFAULT 0,
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
    hsn_id INTEGER,
    cgst DECIMAL(5,2),
    sgst DECIMAL(5,2),
    igst DECIMAL(5,2),
    utgst DECIMAL(5,2),
    is_active BOOLEAN,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Trigger for dispatch_details
CREATE OR REPLACE FUNCTION wms.dispatch_details_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.dispatch_details_history(
            detail_id, header_id, material_id, picking_detail_id, qty, uom_id, hsn_id, cgst, sgst, igst, utgst, is_active, operation, operation_at, operation_by
        ) VALUES (
            NEW.id, NEW.header_id, NEW.material_id, NEW.picking_detail_id, NEW.qty, NEW.uom_id, NEW.hsn_id, NEW.cgst, NEW.sgst, NEW.igst, NEW.utgst, NEW.is_active, 'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.dispatch_details_history(
                detail_id, header_id, material_id, picking_detail_id, qty, uom_id, is_active, operation, operation_at, operation_by
            ) VALUES (
                NEW.id, NEW.header_id, NEW.material_id, NEW.picking_detail_id, NEW.qty, NEW.uom_id, NEW.is_active, 'DELETE', NEW.lua, NEW.lub
            );
        ELSIF (OLD.is_active = false AND NEW.is_active = true) THEN
            INSERT INTO wms.dispatch_details_history(
                detail_id, header_id, material_id, picking_detail_id, qty, uom_id, is_active, operation, operation_at, operation_by
            ) VALUES (
                NEW.id, NEW.header_id, NEW.material_id, NEW.picking_detail_id, NEW.qty, NEW.uom_id, NEW.is_active, 'INSERT', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER dispatch_details_insert_trigger
    AFTER INSERT ON wms.dispatch_details
    FOR EACH ROW
    EXECUTE FUNCTION wms.dispatch_details_trigger();

CREATE TRIGGER dispatch_details_update_trigger
    AFTER UPDATE ON wms.dispatch_details
    FOR EACH ROW
    EXECUTE FUNCTION wms.dispatch_details_trigger();

