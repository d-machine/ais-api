-- Drop if exists
-- DROP TABLE IF EXISTS wms.purchase_order_details;
-- DROP TABLE IF EXISTS wms.purchase_order_details_history;
-- DROP FUNCTION IF EXISTS wms.purchase_order_details_trigger;

-- Create purchase_order_details table
CREATE TABLE IF NOT EXISTS wms.purchase_order_details(
    id SERIAL PRIMARY KEY,
    header_id INTEGER NOT NULL REFERENCES wms.purchase_order_header(id),
    entry_no VARCHAR(10) NOT NULL,
    row_no VARCHAR(5) NOT NULL,
    item_id INTEGER NOT NULL REFERENCES wms.material(id),
    euom INTEGER NOT NULL REFERENCES wms.uom(id),
    puom INTEGER NOT NULL REFERENCES wms.uom(id),
    quom INTEGER NOT NULL REFERENCES wms.uom(id),
    rate_per_pc DOUBLE PRECISION NOT NULL,
    eqty DECIMAL(15,3) NOT NULL,
    pqty DECIMAL(15,3) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    iqty DECIMAL(15,3) DEFAULT 0,
    hsn_id INTEGER REFERENCES wms.hsn(id),
    cgst DECIMAL(5,2) NOT NULL DEFAULT 0,
    sgst DECIMAL(5,2) NOT NULL DEFAULT 0,
    igst DECIMAL(5,2) NOT NULL DEFAULT 0,
    utgst DECIMAL(5,2) NOT NULL DEFAULT 0,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active boolean NOT NULL DEFAULT true,
    remarks VARCHAR(255),
    UNIQUE(entry_no, row_no)
);

-- Create temporal table for purchase_order_details
CREATE TABLE IF NOT EXISTS wms.purchase_order_details_history(
    history_id SERIAL PRIMARY KEY,
    purchase_details_id INTEGER,
    header_id INTEGER,
    entry_no VARCHAR(10),
    row_no VARCHAR(5),
    item_id INTEGER,
    euom INTEGER,
    puom INTEGER,
    quom INTEGER,
    rate_per_pc DOUBLE PRECISION,
    eqty DECIMAL(15,3),
    pqty DECIMAL(15,3),
    amount DECIMAL(15,2),
    iqty DECIMAL(15,3),
    hsn_id INTEGER,
    cgst DECIMAL(5,2),
    sgst DECIMAL(5,2),
    igst DECIMAL(5,2),
    utgst DECIMAL(5,2),
    remarks VARCHAR(255),
    is_active boolean NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Create trigger function for purchase_order_details
CREATE OR REPLACE FUNCTION wms.purchase_order_details_trigger()
RETURNS trigger AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.purchase_order_details_history(
            purchase_details_id, header_id, entry_no, row_no, item_id,
            euom, puom, quom, rate_per_pc, eqty, pqty, amount, iqty,
            hsn_id, cgst, sgst, igst, utgst,
            remarks, is_active, operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.header_id, NEW.entry_no, NEW.row_no, NEW.item_id,
            NEW.euom, NEW.puom, NEW.quom, NEW.rate_per_pc, NEW.eqty, NEW.pqty, NEW.amount, NEW.iqty,
            NEW.hsn_id, NEW.cgst, NEW.sgst, NEW.igst, NEW.utgst,
            NEW.remarks, NEW.is_active, 'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.purchase_order_details_history(
                purchase_details_id, header_id, entry_no, row_no, item_id,
                euom, puom, quom, rate_per_pc, eqty, pqty, amount, iqty,
                hsn_id, cgst, sgst, igst, utgst,
                remarks, is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.header_id, NEW.entry_no, NEW.row_no, NEW.item_id,
                NEW.euom, NEW.puom, NEW.quom, NEW.rate_per_pc, NEW.eqty, NEW.pqty, NEW.amount, NEW.iqty,
                NEW.hsn_id, NEW.cgst, NEW.sgst, NEW.igst, NEW.utgst,
                NEW.remarks, NEW.is_active, 'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.purchase_order_details_history(
                purchase_details_id, header_id, entry_no, row_no, item_id,
                euom, puom, quom, rate_per_pc, eqty, pqty, amount, iqty,
                hsn_id, cgst, sgst, igst, utgst,
                remarks, is_active, operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.header_id, NEW.entry_no, NEW.row_no, NEW.item_id,
                NEW.euom, NEW.puom, NEW.quom, NEW.rate_per_pc, NEW.eqty, NEW.pqty, NEW.amount, NEW.iqty,
                NEW.hsn_id, NEW.cgst, NEW.sgst, NEW.igst, NEW.utgst,
                NEW.remarks, NEW.is_active, 'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--Create trigger for purchase_oder_details
DROP TRIGGER IF EXISTS purchase_order_details_insert_trigger ON wms.purchase_order_details;
CREATE TRIGGER purchase_order_details_insert_trigger
    AFTER INSERT ON wms.purchase_order_details
    FOR EACH ROW
    EXECUTE FUNCTION wms.purchase_order_details_trigger();
            
DROP TRIGGER IF EXISTS purchase_order_details_update_trigger ON wms.purchase_order_details;
CREATE TRIGGER purchase_order_details_update_trigger
    AFTER UPDATE ON wms.purchase_order_details
    FOR EACH ROW
    EXECUTE FUNCTION wms.purchase_order_details_trigger();       

DROP TRIGGER IF EXISTS purchase_order_details_delete_trigger ON wms.purchase_order_details;
CREATE TRIGGER purchase_order_details_delete_trigger
    AFTER DELETE ON wms.purchase_order_details
    FOR EACH ROW
    EXECUTE FUNCTION wms.purchase_order_details_trigger();