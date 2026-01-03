-- Drop if exist
DROP TABLE IF EXISTS wms.inward_details_history CASCADE;
DROP TABLE IF EXISTS wms.inward_details CASCADE;

-- Create inward_details table
CREATE TABLE IF NOT EXISTS wms.inward_details (
    id SERIAL PRIMARY KEY,
    header_id INTEGER NOT NULL REFERENCES wms.inward_header(id) ON DELETE CASCADE,
    entry_no VARCHAR(50) NOT NULL,
    row_no VARCHAR(5) NOT NULL,
    material_id INTEGER NOT NULL REFERENCES wms.material(id),
    po_detail_id INTEGER REFERENCES wms.purchase_order_details(id),
    quom INTEGER REFERENCES wms.uom(id),
    euom INTEGER NOT NULL REFERENCES wms.uom(id),
    puom INTEGER REFERENCES wms.uom(id),
    eqty DECIMAL(15,3),
    pqty DECIMAL(15,3),
    pur_rate DECIMAL(15,2),
    amount DECIMAL(15,2),
    is_active BOOLEAN NOT NULL DEFAULT true,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    expiry_dt DATE,
    batch_no VARCHAR(100),
    remarks VARCHAR(255),
    UNIQUE(entry_no, row_no)
);

-- Create temporal table for inward_details
CREATE TABLE IF NOT EXISTS wms.inward_details_history (
    history_id SERIAL PRIMARY KEY,
    inward_details_id INTEGER,
    header_id INTEGER,
    entry_no VARCHAR(50),
    row_no VARCHAR(5),
    material_id INTEGER,
    po_detail_id INTEGER,
    quom INTEGER,
    euom INTEGER,
    puom INTEGER,
    eqty DECIMAL(15,3),
    pqty DECIMAL(15,3),
    pur_rate DECIMAL(15,2),
    amount DECIMAL(15,2),
    expiry_dt DATE,
    batch_no VARCHAR(100),
    is_active BOOLEAN NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

-- Create trigger function for inward_details
CREATE OR REPLACE FUNCTION wms.inward_details_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.inward_details_history(
            inward_details_id, header_id, entry_no, row_no, material_id, po_detail_id,
            quom, euom, puom, eqty, pqty, pur_rate, amount, expiry_dt, batch_no, is_active,
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id, NEW.header_id, NEW.entry_no, NEW.row_no, NEW.material_id, NEW.po_detail_id,
            NEW.quom, NEW.euom, NEW.puom, NEW.eqty, NEW.pqty, NEW.pur_rate, NEW.amount, NEW.expiry_dt, NEW.batch_no, NEW.is_active,
            'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.inward_details_history(
                inward_details_id, header_id, entry_no, row_no, material_id, po_detail_id,
                quom, euom, puom, eqty, pqty, pur_rate, amount, expiry_dt, batch_no, is_active,
                operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.header_id, NEW.entry_no, NEW.row_no, NEW.material_id, NEW.po_detail_id,
                NEW.quom, NEW.euom, NEW.puom, NEW.eqty, NEW.pqty, NEW.pur_rate, NEW.amount, NEW.expiry_dt, NEW.batch_no, NEW.is_active,
                'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.inward_details_history(
                inward_details_id, header_id, entry_no, row_no, material_id, po_detail_id,
                quom, euom, puom, eqty, pqty, pur_rate, amount, expiry_dt, batch_no, is_active,
                operation, operation_at, operation_by
            )
            VALUES (
                NEW.id, NEW.header_id, NEW.entry_no, NEW.row_no, NEW.material_id, NEW.po_detail_id,
                NEW.quom, NEW.euom, NEW.puom, NEW.eqty, NEW.pqty, NEW.pur_rate, NEW.amount, NEW.expiry_dt, NEW.batch_no, NEW.is_active,
                'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO wms.inward_details_history(
            inward_details_id, header_id, entry_no, row_no, material_id, po_detail_id,
            quom, euom, puom, eqty, pqty, pur_rate, amount, expiry_dt, is_active,
            operation, operation_at, operation_by
        )
        VALUES (
            OLD.id, OLD.header_id, OLD.entry_no, OLD.row_no, OLD.material_id, OLD.po_detail_id,
            OLD.quom, OLD.euom, OLD.puom, OLD.eqty, OLD.pqty, OLD.pur_rate, OLD.amount, OLD.expiry_dt, false,
            'DELETE', NOW(), OLD.lub
        );
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for inward_details
DROP TRIGGER IF EXISTS inward_details_insert_trigger ON wms.inward_details;
CREATE TRIGGER inward_details_insert_trigger
    AFTER INSERT ON wms.inward_details
    FOR EACH ROW
    EXECUTE FUNCTION wms.inward_details_trigger();
            
DROP TRIGGER IF EXISTS inward_details_update_trigger ON wms.inward_details;
CREATE TRIGGER inward_details_update_trigger
    AFTER UPDATE ON wms.inward_details
    FOR EACH ROW
    EXECUTE FUNCTION wms.inward_details_trigger();       

DROP TRIGGER IF EXISTS inward_details_delete_trigger ON wms.inward_details;
CREATE TRIGGER inward_details_delete_trigger
    AFTER DELETE ON wms.inward_details
    FOR EACH ROW
    EXECUTE FUNCTION wms.inward_details_trigger();
