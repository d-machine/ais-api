-- DROP IF EXISTS
-- DROP TABLE IF EXISTS wms.picking_list_order;
-- DROP TABLE IF EXISTS wms.picking_list_order_history;
-- DROP FUNCTION IF EXISTS wms.picking_list_order_trigger;

-- Create picking_list_order table
CREATE TABLE IF NOT EXISTS wms.picking_list_order(
    id SERIAL PRIMARY KEY,
    header_id INTEGER NOT NULL REFERENCES wms.picking_list_header(id),
    order_id INTEGER NOT NULL REFERENCES wms.sales_order_header(id),
    item_id INTEGER NOT NULL REFERENCES wms.material(id),
    qty INTEGER NOT NULL,
    descr VARCHAR(255),
    is_active boolean NOT NULL DEFAULT true,
    status VARCHAR(255),
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);

--Create temporal table for picking_list_order
CREATE TABLE IF NOT EXISTS wms.picking_list_order_history(
    history_id SERIAL PRIMARY KEY,
    picking_order_id INTEGER,
    header_id INTEGER,
    order_id INTEGER,
    item_id INTEGER,
    qty INTEGER,
    descr VARCHAR(255),
    status VARCHAR(255),
    is_active boolean NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Create trigger function for picking_list_order
CREATE OR REPLACE FUNCTION wms.picking_list_order_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.picking_list_order_history(
            picking_order_id, header_id, order_id, item_id, qty, descr, status, is_active, operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.header_id, NEW.order_id, NEW.item_id, NEW.qty, NEW.descr, NEW.status, NEW.is_active, 'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.picking_list_order_history(
                picking_order_id, header_id, order_id, item_id, qty, descr, status, is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.header_id, NEW.order_id, NEW.item_id, NEW.qty, NEW.descr, NEW.status, NEW.is_active, 'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.picking_list_order_history(
                picking_order_id, header_id, order_id, item_id, qty, descr, status, is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.header_id, NEW.order_id, NEW.item_id, NEW.qty, NEW.descr, NEW.status, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for picking_list_order
DROP TRIGGER IF EXISTS picking_order_insert_trigger ON wms.picking_list_order;
CREATE TRIGGER picking_order_insert_trigger
    AFTER INSERT ON wms.picking_list_order
    FOR EACH ROW
    EXECUTE FUNCTION wms.picking_list_order_trigger();

DROP TRIGGER IF EXISTS picking_order_update_trigger ON wms.picking_list_order;
CREATE TRIGGER picking_order_update_trigger
    AFTER INSERT ON wms.picking_list_order
    FOR EACH ROW
    EXECUTE FUNCTION wms.picking_list_order_trigger();

DROP TRIGGER IF EXISTS picking_order_delete_trigger ON wms.picking_list_order;
CREATE TRIGGER picking_order_delete_trigger
    AFTER INSERT ON wms.picking_list_order
    FOR EACH ROW
    EXECUTE FUNCTION wms.picking_list_order_trigger();