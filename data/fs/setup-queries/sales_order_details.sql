-- Drop if exist
-- DROP TABLE IF EXISTS wms.sales_order_details;
-- DROP TABLE IF EXISTS wms.sales_order_details_history;
-- DROP TABLE IF EXISTS wms.sales_order_details_trigger;

-- Create sales_order_details table
CREATE TABLE IF NOT EXISTS wms.sales_order_details(
    id SERIAL PRIMARY KEY,
    header_id INTEGER NOT NULL REFERENCES wms.sales_order_header(id),
    item_id INTEGER NOT NULL REFERENCES wms.material(id),
    uom_pc_id INTEGER NOT NULL REFERENCES wms.uom(id),
    uom_package_id INTEGER NOT NULL REFERENCES wms.uom(id),
    rate_per_pc DOUBLE PRECISION NOT NULL,
    no_of_pc INTEGER NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active boolean NOT NULL DEFAULT true,
    status VARCHAR(255)
    remarks VARCHAR(255)
);

-- Create temporal table for sales_order_details
CREATE TABLE IF NOT EXISTS wms.sales_order_details_history(
    history_id SERIAL PRIMARY KEY,
    sales_order_details_id INTEGER,
    header_id INTEGER,
    item_id INTEGER,
    uom_pc_id INTEGER,
    uom_package_id INTEGER,
    rate_per_pc DOUBLE PRECISION,
    no_of_pc INTEGER,
    amount DOUBLE PRECISION,
    status VARCHAR(255),
    remarks VARCHAR(255),
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

--Create trigger function for sales_order_details
CREATE OR REPLACE FUNCTION wms.sales_order_details_trigger()
RETURNS trigger AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO wms.sales_order_details_history(
            sales_order_details_id,
            header_id,
            item_id,
            uom_pc_id,
            uom_package_id,
            rate_per_pc,
            no_of_pc,
            amount,
            status,
            remarks,
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id,
            NEW.header_id,
            NEW.item_id,
            NEW.uom_pc_id,
            NEW.uom_package_id,
            NEW.rate_per_pc,
            NEW.no_of_pc,
            NEW.amount,
            NEW.status,
            NEW.remarks,
            'INSERT', NEW.lua, NEW.lub
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO wms.sales_order_details_history(
                sales_order_details_id,
                header_id,
                item_id,
                uom_pc_id,
                uom_package_id,
                rate_per_pc,
                no_of_pc,
                amount,
                status,
                remarks,
                operation, operation_at, operation_by
            )
            VALUES (
                NEW.id,
                NEW.header_id,
                NEW.item_id,
                NEW.uom_pc_id,
                NEW.uom_package_id,
                NEW.rate_per_pc,
                NEW.no_of_pc,
                NEW.amount,
                NEW.status,
                NEW.remarks,
                'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO wms.sales_order_details_history(
                sales_order_details_id,
                header_id,
                item_id,
                uom_pc_id,
                uom_package_id,
                rate_per_pc,
                no_of_pc,
                amount,
                status,
                remarks,
                operation, operation_at, operation_by
            )
            VALUES (
                NEW.id,
                NEW.header_id,
                NEW.item_id,
                NEW.uom_pc_id,
                NEW.uom_package_id,
                NEW.rate_per_pc,
                NEW.no_of_pc,
                NEW.amount,
                NEW.status,
                NEW.remarks,
                'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO wms.sales_order_details_history(
            sales_order_details_id,
            header_id,
            item_id,
            uom_pc_id,
            uom_package_id,
            rate_per_pc,
            no_of_pc,
            amount,
            status,
            remarks,
            operation, operation_at, operation_by
        )
        VALUES (
            OLD.id,
            OLD.header_id,
            OLD.item_id,
            OLD.uom_pc_id,
            OLD.uom_package_id,
            OLD.rate_per_pc,
            OLD.no_of_pc,
            OLD.amount,
            OLD.status,
            OLD.remarks,
            'DELETE', NEW.lua, NEW.lub
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for sales_order-details
DROP TRIGGER IF EXISTS sales_order_details_insert_trigger ON wms.sales_order_details;
CREATE TRIGGER sales_order_details_insert_trigger
    BEFORE INSERT ON wms.sales_order_details
    FOR EACH ROW
    EXECUTE FUNCTION wms.sales_order_details_trigger();
            
DROP TRIGGER IF EXISTS sales_order_details_update_trigger ON wms.sales_order_details;
CREATE TRIGGER sales_order_details_update_trigger
    BEFORE INSERT ON wms.sales_order_details
    FOR EACH ROW
    EXECUTE FUNCTION wms.sales_order_details_trigger();       

DROP TRIGGER IF EXISTS sales_order_details_delete_trigger ON wms.sales_order_details;
CREATE TRIGGER sales_order_details_delete_trigger
    BEFORE INSERT ON wms.sales_order_details
    FOR EACH ROW
    EXECUTE FUNCTION wms.sales_order_details_trigger();          

            