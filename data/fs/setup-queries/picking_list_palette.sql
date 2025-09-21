-- DROP IF EXISTS
-- DROP TABLE IF EXISTS wms.picking_list_palette;
-- DROP TABLE IF EXISTS wms.picking_list_palette_history;
-- DROP FUNCTION IF EXISTS wms.picking_list_palette_trigger;

--Create picking_list_palette table
CREATE TABLE IF NOT EXISTS wms.picking_list_palette(
    id SERIAL PRIMARY KEY,
    header_id INTEGER NOT NULL REFERENCES wms.picking_list_header(id),
    palette_id INTEGER NOT NULL REFERENCES wms.palette(id),
    item_id INTEGER NOT NULL REFERENCES wms.material(id),
    qty INTEGER NOT NULL,
    descr VARCHAR(255),
    is_active boolean NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    status VARCHAR(255)
);

--Create temporal table for picking_list_palette
CREATE TABLE IF NOT EXISTS wms.picking_list_palette_history(
    history_id SERIAL PRIMARY KEY,
    picking_palette_id INTEGER,
    header_id INTEGER,
    palette_id INTEGER,
    item_id INTEGER,
    qty INTEGER,
    descr VARCHAR(255),
    status VARCHAR(255),
    is_active boolean NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

--Create trigger function for picking_list_palette
CREATE OR REPLACE FUNCTION wms.picking_list_palette_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.picking_list_palette_history(
            picking_palette_id, header_id, palette_id, item_id, qty, descr, status, is_active, operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.header_id, NEW.palette_id, NEW.item_id, NEW.qty, NEW.descr, NEW.status, NEW.is_active, 'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.picking_list_palette_history(
                picking_palette_id, header_id, palette_id, item_id, qty, descr, status, is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.header_id, NEW.palette_id, NEW.item_id, NEW.qty, NEW.descr, NEW.status, NEW.is_active, 'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.picking_list_palette_history(
                picking_palette_id, header_id, palette_id, item_id, qty, descr, status, is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.header_id, NEW.palette_id, NEW.item_id, NEW.qty, NEW.descr, NEW.status, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--Create triggers for picking_list_palette

DROP TRIGGER IF EXISTS picking_palette_insert_trigger ON wms.picking_list_palette;
CREATE TRIGGER picking_palette_insert_trigger
    AFTER INSERT ON wms.picking_list_palette
    FOR EACH ROW
    EXECUTE FUNCTION wms.picking_list_palette_trigger();

DROP TRIGGER IF EXISTS picking_palette_update_trigger ON wms.picking_list_palette;
CREATE TRIGGER picking_palette_update_trigger
    AFTER UPDATE ON wms.picking_list_palette
    FOR EACH ROW
    EXECUTE FUNCTION wms.picking_list_palette_trigger();

DROP TRIGGER IF EXISTS picking_palette_delete_trigger ON wms.picking_list_palette;
CREATE TRIGGER picking_palette_delete_trigger
    AFTER DELETE ON wms.picking_list_palette
    FOR EACH ROW
    EXECUTE FUNCTION wms.picking_list_palette_trigger();


