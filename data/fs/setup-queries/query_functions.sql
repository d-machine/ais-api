---------------------------** USER MANAGEMENT **---------------------------
-- Insert a user
CREATE OR REPLACE FUNCTION administration.insert_user(
    username VARCHAR(255),
    password VARCHAR(255),
    email VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    reports_to INT,
    current_user_id INT,
    role_ids TEXT
) RETURNS INT AS $$
    DECLARE new_user_id INT;
BEGIN

    INSERT INTO administration.user (username, password, email, first_name, last_name,
                      reports_to, lub)
    VALUES (username, password, email, first_name, last_name, reports_to, current_user_id)
    RETURNING id INTO new_user_id;

    INSERT INTO administration.user_role (user_id, role_id)
    SELECT new_user_id, unnest(string_to_array(role_ids, ',')::int[]);

    RETURN new_user_id;

END;
$$ LANGUAGE plpgsql;

-- Update a user
CREATE OR REPLACE FUNCTION administration.update_user(
    user_id INT,
    username VARCHAR(255),
    email VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    reports_to INT,
    current_user_id INT,
    role_ids TEXT
) RETURNS INT AS $$
BEGIN
    UPDATE administration.user
    SET username = username, email = email, first_name = first_name, last_name = last_name,
        reports_to = reports_to, lub = current_user_id
    WHERE id = user_id;

    PERFORM administration.delete_all_roles_for_user(user_id, current_user_id);

    INSERT INTO administration.user_role (user_id, role_id)
    SELECT user_id, unnest(string_to_array(role_ids, ',')::int[]);

    RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Change password
CREATE OR REPLACE FUNCTION administration.change_password(
    user_id INT,
    password VARCHAR(255),
    current_user_id INT
) RETURNS INT AS $$
BEGIN
    UPDATE administration.user
    SET password = password, lub = current_user_id
    WHERE id = user_id;
    RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Delete a user
CREATE OR REPLACE FUNCTION administration.delete_user(
    user_id INT,
    current_user_id INT
) RETURNS INT AS $$
BEGIN
    PERFORM administration.delete_all_roles_for_user(user_id, current_user_id);

    INSERT INTO administration.user_history (
        user_id, email, first_name, last_name, username, password, reports_to,
        operation, operation_at, operation_by
    )
    SELECT 
        id, email, first_name, last_name, username, password, reports_to,
        'DELETE', NOW(), current_user_id
    FROM administration.user
    WHERE id = user_id;

    DELETE FROM administration.user WHERE id = user_id;
    RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Delete all roles for a user
CREATE OR REPLACE FUNCTION administration.delete_all_roles_for_user(
    p_user_id INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    -- Insert into history before deletion
    INSERT INTO administration.user_role_history (
        user_role_id, user_id, role_id,
        operation, operation_at, operation_by
    )
    SELECT 
        ur.id, ur.user_id, ur.role_id,
        'DELETE', NOW(), deleted_by_user_id
    FROM administration.user_role ur
    WHERE ur.user_id = p_user_id;

    -- Delete the user_role
    DELETE FROM administration.user_role ur WHERE ur.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;


---------------------------** ROLE MANAGEMENT **---------------------------
-- Insert a role
CREATE OR REPLACE FUNCTION administration.insert_role(
    name VARCHAR(255),
    description VARCHAR(255),
    current_user_id INT
) RETURNS INT AS $$
DECLARE new_role_id INT;
BEGIN
    INSERT INTO administration.role (name, description, lub)
    VALUES (name, description, current_user_id)
    RETURNING id INTO new_role_id;
    return new_role_id;
END;
$$ LANGUAGE plpgsql;

-- Update a role
CREATE OR REPLACE FUNCTION administration.update_role(
    role_id INT,
    name VARCHAR(255),
    description VARCHAR(255),
    current_user_id INT
) RETURNS INT AS $$
BEGIN
    UPDATE administration.role
    SET name = name, description = description, lub = current_user_id
    WHERE id = role_id;
    RETURN role_id;
END;
$$ LANGUAGE plpgsql;


-- Insert claim
CREATE OR REPLACE FUNCTION administration.insert_claim(
    role_id INT,
    resource_id INT,
    access_type_ids TEXT,
    access_level_id TEXT,
    current_user_id INT
) RETURNS INT AS $$
DECLARE new_claim_id INT;
BEGIN
    INSERT INTO administration.claim (role_id, resource_id, access_type_ids, access_level_id, lub)
    VALUES (role_id, resource_id, access_type_ids, access_level_id, current_user_id)
    RETURNING id INTO new_claim_id;

    RETURN new_claim_id;
END;
$$ LANGUAGE plpgsql;

-- Update claim
CREATE OR REPLACE FUNCTION administration.update_claim(
    claim_id INT,
    role_id INT,
    resource_id INT,
    access_type_ids TEXT,
    access_level_id TEXT,
    current_user_id INT
) RETURNS INT AS $$
BEGIN
    UPDATE claim
    SET role_id = role_id, resource_id = resource_id, access_type_ids = access_type_ids, access_level_id = access_level_id, lub = current_user_id
    WHERE id = claim_id;
    RETURN claim_id;
END;
$$ LANGUAGE plpgsql;

-- Insert or update claim
CREATE OR REPLACE FUNCTION administration.insert_or_update_role_claim(
    role_id INT,
    resource_id INT,
    access_type_ids TEXT,
    access_level_id TEXT,
    current_user_id INT,
    claim_id INT DEFAULT NULL
) RETURNS INT AS $$

    DECLARE result_id INT;
BEGIN
    IF claim_id IS NULL THEN
        result_id := administration.insert_claim(role_id, resource_id, access_type_ids, access_level_id, current_user_id);
    ELSE
        result_id := administration.update_claim(claim_id, role_id, resource_id, access_type_ids, access_level_id, current_user_id);
    END IF;
    RETURN result_id;
END;
$$ LANGUAGE plpgsql;

-- Delete a claim
CREATE OR REPLACE FUNCTION administration.delete_claim(
    claim_id INT,
    current_user_id INT
) RETURNS INT AS $$
BEGIN
    INSERT INTO administration.claim_history (claim_id, role_id, resource_id, access_level_id, access_type_ids, operation, operation_at, operation_by)
    SELECT id, role_id, resource_id, access_level_id, access_type_ids, 'DELETE', NOW(), current_user_id
    FROM administration.claim
    WHERE id = claim_id;

    DELETE FROM administration.claim WHERE id = claim_id;
    RETURN claim_id;
END;
$$ LANGUAGE plpgsql;

-- Delete all claims for a role
CREATE OR REPLACE FUNCTION administration.delete_all_claims_for_role(
    p_role_id INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    -- Insert into history before deletion
    INSERT INTO administration.claim_history (
        claim_id, role_id, resource_id, access_level_id, access_type_ids,
        operation, operation_at, operation_by
    )
    SELECT 
        id, role_id, resource_id, access_level_id, access_type_ids,
        'DELETE', NOW(), deleted_by_user_id
    FROM administration.claim
    WHERE role_id = p_role_id;

    -- Delete the claim
    DELETE FROM administration.claim WHERE role_id = p_role_id;
END;
$$ LANGUAGE plpgsql;

-- Delete all users for a role
CREATE OR REPLACE FUNCTION administration.delete_all_users_for_role(
    p_role_id INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    -- Insert into history before deletion
    INSERT INTO administration.user_role_history (
        user_role_id, user_id, role_id,
        operation, operation_at, operation_by
    )
    SELECT 
        ur.id, ur.user_id, ur.role_id,
        'DELETE', NOW(), deleted_by_user_id
    FROM administration.user_role ur
    WHERE ur.role_id = p_role_id;

    -- Delete the user_role
    DELETE FROM administration.user_role ur WHERE ur.role_id = p_role_id;
END;
$$ LANGUAGE plpgsql;

-- Delete a role
CREATE OR REPLACE FUNCTION administration.delete_role(
    p_role_id INT,
    current_user_id INT
) RETURNS INT AS $$
BEGIN
    INSERT INTO administration.role_history (role_id, name, description, operation, operation_at, operation_by)
    SELECT id, name, description, 'DELETE', NOW(), current_user_id
    FROM administration.role
    WHERE id = p_role_id;

    -- Delete all users for this role
    PERFORM administration.delete_all_users_for_role(p_role_id, current_user_id);

    -- Delete all claims for this role
    PERFORM administration.delete_all_claims_for_role(p_role_id, current_user_id);

    DELETE FROM administration.role WHERE id = p_role_id;
    RETURN p_role_id;
END;
$$ LANGUAGE plpgsql;


---------------------------** RESOURCE MANAGEMENT **---------------------------
-- Insert a resource
CREATE OR REPLACE FUNCTION administration.insert_resource(
    name VARCHAR(255),
    list_config_file VARCHAR(255),
    parent_id INT,
    current_user_id INT
) RETURNS INT AS $$
BEGIN
    INSERT INTO administration.resource (name, list_config_file, parent_id, lub)
    VALUES (name, list_config_file, parent_id, current_user_id)
    RETURNING id;
END;
$$ LANGUAGE plpgsql;

-- Update a resource
CREATE OR REPLACE FUNCTION administration.update_resource(
    resource_id INT,
    name VARCHAR(255),
    list_config_file VARCHAR(255),
    parent_id INT,
    current_user_id INT
) RETURNS INT AS $$
BEGIN
    UPDATE administration.resource
    SET name = name, list_config_file = list_config_file, parent_id = parent_id, lub = current_user_id
    WHERE id = resource_id;
    RETURN resource_id;
END;
$$ LANGUAGE plpgsql;


---------------------------** Country Master **---------------------------
-- Function to insert in country_master
CREATE OR REPLACE FUNCTION wms.insert_country(
    country_name VARCHAR(255),
    country_code VARCHAR(3),
    description VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_country_id INT;
BEGIN
    INSERT INTO wms.country_master (name, code, descr, lub)
    VALUES (country_name, country_code, description, current_user_id)
    RETURNING id into new_country_id;
    RETURN new_country_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update country_master
CREATE OR REPLACE FUNCTION wms.update_country(
    country_master_id INT,
    country_name VARCHAR(255),
    country_code VARCHAR(3),
    description VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.country_master
    SET name = country_name, code = country_code, descr = description, lub = current_user_id
    WHERE id = country_master_id;
    RETURN country_master_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete country_master
CREATE OR REPLACE FUNCTION wms.delete_country(
    country_master_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS INT AS $$
BEGIN
    -- Delete all states associated with this country
    PERFORM wms.delete_state_by_country(country_master_id_to_delete, deleted_by_user_id);

    -- Delete country
    UPDATE wms.country_master
    SET is_active = false, lub = deleted_by_user_id
    WHERE id = country_master_id_to_delete;
    RETURN country_master_id_to_delete;
END;
$$ LANGUAGE plpgsql;

---------------------------** State Master **---------------------------

-- Function to insert in state_master
CREATE OR REPLACE FUNCTION wms.insert_state(
    name VARCHAR(255),
    code VARCHAR(3),
    descr VARCHAR(255),
    country_id INT,
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_state_id INT;
BEGIN
    INSERT INTO wms.state_master (name, code, descr, country_id, lub)
    VALUES (name, code, descr, country_id, current_user_id)
    RETURNING id into new_state_id;
    RETURN new_state_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update state_master
CREATE OR REPLACE FUNCTION wms.update_state(
    state_master_id INT,
    name VARCHAR(255),
    code VARCHAR(3),
    descr VARCHAR(255),
    country_id INT,
    current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.state_master
    SET name = name, code = code, descr = descr, country_id = country_id, lub = current_user_id
    WHERE id = state_master_id;
    RETURN state_master_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete state_master
CREATE OR REPLACE FUNCTION wms.delete_state(
    state_master_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    -- Delete state
    UPDATE wms.state_master
    SET is_active = false, lub = deleted_by_user_id
    WHERE id = state_master_id_to_delete;
    RETURN state_master_id_to_delete;
END;
$$ LANGUAGE plpgsql;

-- Function to delete all states associated with a country
CREATE OR REPLACE FUNCTION wms.delete_state_by_country(
    country_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
) RETURNS VOID AS $$
BEGIN
    UPDATE wms.state_master
    SET is_active = false, lub = deleted_by_user_id
    WHERE country_id = country_id_to_delete;
END;
$$ LANGUAGE plpgsql;


---------------------------** Item Category Master **---------------------------


-- Function to insert in item_category_master
CREATE OR REPLACE FUNCTION wms.insert_item_category(
    item_category_name VARCHAR(255),
    description VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
DECLARE new_item_category_id INT;
BEGIN 
    INSERT INTO wms.item_category_master(name,descr,lub)
    VALUES (item_category_name,description,current_user_id)
    RETURNING id INTO new_item_category_id;
    RETURN new_item_category_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update item_category_master
CREATE OR REPLACE FUNCTION wms.update_item_category(
    item_category_master_id INT,
    item_category_name VARCHAR(255),
    description VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    UPDATE wms.item_category_master
    SET name = item_category_name,descr = description,lub = current_user_id
    WHERE id =item_category_master_id;
    RETURN item_category_master_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete item_category_master
CREATE OR REPLACE FUNCTION wms.delete_item_category(
    item_category_master_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    -- Delete all brands associated with this item category
    PERFORM wms.delete_item_brand_by_item_category(item_category_master_id_to_delete,deleted_by_user_id);

    --Delete item category
    UPDATE wms.item_category_master
    SET is_active = false,lub = deleted_by_user_id
    WHERE id = item_category_master_id_to_delete;
    RETURN item_category_master_id_to_delete;
END;
$$ LANGUAGE plpgsql;


---------------------------** Item Brand **---------------------------


-- Function to insert in item_brand
CREATE OR REPLACE FUNCTION wms.insert_item_brand(
    brand_name VARCHAR(255),
    category_id INTEGER,
    descr VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
DECLARE new_item_brand_id INT;
BEGIN 
    INSERT INTO wms.item_brand(brand_name,category_id,descr,lub)
    VALUES (brand_name,category_id,descr,curren_user_id)
    RETURNING id INTO new_item_brand_id;
    RETURN new_item_brand_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update item_brand
CREATE OR REPLACE FUNCTION wms.update_item_brand(
    item_brand_id INT,
    brand_name VARCHAR(255),
    category_id INTEGER,
    descr VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
BEGIN 
    UPDATE wms.item_brand
    SET brand_name = brand_name,category_id = category_id,descr = descr,lub = curren_user_id
    WHERE id = item_brand_id;
    RETURN item_brand_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete item_brand
CREATE OR REPLACE  FUNCTION wms.delete_item_brand(
    item_brand_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNS INT AS $$
BEGIN 
    UPDATE wms.item_brand
    SET is_active = false ,lub = deleted_by_user_id
    WHERE id = item_brand_id_to_delete;
    RETURN item_brand_id_to_delete;
END;
$$ LANGUAGE plpgsql;

-- Function to delete all item_brand associated with an item_category
CREATE OR REPLACE FUNCTION wms.delete_item_brand_by_item_category(
    item_category_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNS VOID AS $$
BEGIN
    UPDATE wms.item_brand
    SET is_active = false ,lub = deleted_by_user_id
    WHERE item_category_id = item_category_id_to_delete;
END;
$$ LANGUAGE plpgsql;

---------------------------** Sales Order Header **---------------------------


-- Function to insert in sales_order_header
CREATE OR REPLACE FUNCTION wms.insert_sales_order_header(
    entry_no VARCHAR(6),
    entry_dt TIMESTAMP,
    party_id INTEGER,
    broker_id INTEGER,
    delivery_at_dt INTEGER,
    trsp_id INTEGER,
    year_code VARCHAR(4),
    delivery_dt TIMESTAMP,
    status VARCHAR(255),
    remarks VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_sales_order_id INT;
BEGIN
    INSERT INTO wms.sales_order_header(
        entry_no,
        entry_dt,
        party_id,
        delivery_at_id,
        trsp_id,
        year_code,
        delivery_dt,
        status,
        remarks,
        lub
    )
    VALUES (
        entry_no, 
        entry_dt,
        party_id,
        broker_id,
        delivery_at_dt,
        trsp_id,
        year_code,
        delivery_dt,
        status,
        remarks,
        current_user_id
    )
    RETURNING id INTO new_sales_order_id;
    RETURN new_sales_order_id;
END;
$$ LANGUAGE plpgsql;

--Function to update sales_order_header
CREATE OR  REPLACE FUNCTION wms.update_sales_order_header(
    sales_order_id INT,
    entry_no VARCHAR(6),
    entry_dt TIMESTAMP,
    party_id INTEGER,
    broker_id INTEGER,
    delivery_at_dt INTEGER,
    trsp_id INTEGER,
    year_code VARCHAR(4),
    delivery_dt TIMESTAMP,
    status VARCHAR(255),
    remarks VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    UPDATE  wms.sales_order_header
    SET entry_no = entry_no,
        entry_dt = entry_dt,
        party_id = party_id,
        delivery_at_id = delivery_at_dt,
        trsp_id = trsp_id,
        year_code = year_code,
        delivery_dt = delivery_dt,
        status =status,
        remarks = remarks,
        lub = current_user_id,
    WHERE id = sales_order_id;
    RETURN sales_order_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete sales_order_header
CREATE OR REPLACE FUNCTION wms.delete_sales_order_header(
    sales_order_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURN INT AS $$
BEGIN
    --Delete all sales details associated with this sales header
    PERFORM wms.delete_sales_details_by_sales_header(sales_order_id_to_delete,deleted_by_user_id);

    -- Delete sales order header
    UPDATE wms.sales_order_header
    SET is_active = false,
        lub = deleted_by_user_id
    WHERE id = sales_order_id_to_delete;
    RETURN sales_order_id_to_delete
END;
$$ LANGUAGE plpgsql;


---------------------------** Sales Order Details **---------------------------


--Function to insert in sales_ order_details
CREATE OR REPLACE FUNCTION wms.insert_sales_order_details(
    header_id INTEGER,
    item_id INTEGER,
    uom_pc_id INTEGER,
    uom_package_id INTEGER,
    rate_per_pc DOUBLE PRECISION,
    no_of_pc INTEGER,
    amount DOUBLE PRECISION,
    status VARCHAR(255),
    remarks VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
DECLARE
    new_sales_order_id INT;
BEGIN
    INSERT INTO wms.sales_order_details(
        header_id,
        item_id,
        uom_pc_id,
        uom_package_id,
        rate_per_pc,
        no_of_pc,
        amount,
        status,
        remarks,
        lub
    )
    VALUES (
        header_id,
        item_id,
        uom_pc_id,
        uom_package_id,
        rate_per_pc,
        no_of_pc,
        amount,
        status,
        remarks,
        current_user_id
    )
    RETURNING id INTO new_sales_order_detail_id;
    RETURN new_sales_order_detail_id;
END;
$$ LANGUAGE plpgsql;

--Function to update sales_order_details
CREATE OR REPLACE FUNCTION wms.update_sales_order_details(
    sales_detail_id INTEGER,
    header_id INTEGER,
    item_id INTEGER,
    uom_pc_id INTEGER,
    uom_package_id INTEGER,
    rate_per_pc DOUBLE PRECISION,
    no_of_pc INTEGER,
    amount DOUBLE PRECISION,
    status VARCHAR(255),
    remarks VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    UPDATE wms.sales_order_details
    SET header_id = header_id,
        item_id = item_id,
        uom_pc_id = uom_pc_id,
        uom_package_id = uom_package_id,
        rate_per_pc = rate_per_pc,
        no_of_pc = no_of_pc,
        amount = amount,
        status = status,
        remarks = remarks,
        lub = current_user_id
    WHERE id = sales_detail_id;
    RETURN sales_detail_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete sales_order_details
CREATE OR REPLACE FUNCTION wms.delete_sales_order_details(
    sales_detail_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    UPDATE wms.sales_order_details
    SET is_active = false,
        lub = deleted_by_user_id
    WHERE id =  sales_detail_id_to_delete;
    RETURN sales_detail_id_to_delete;
END;
$$ LANGUAGE plpgsql;

--Function to delete all sales details associated with a sales header
CREATE OR REPLACE FUNCTION wms.delete_sales_details_by_sales_header(
    header_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNS VOID AS $$
BEGIN 
    UPDATE wms.sales_order_details
    SET is_active = false,
    lub = deleted_by_user_id
    WHERE header_id = header_id_to_delete;
END;
$$ LANGUAGE plpgsql;

---------------------------** Picking List Header **---------------------------


--Function to insert in picking_list_header
CREATE OR REPLACE FUNCTION wms.insert_picking_list_header(
    party_id INTEGER,
    descr VARCHAR(255),
    status VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE 
    new_picking_list_id INT;
BEGIN
    INSERT INTO wms.picking_list_header(party_id,descr,status,lub)
    VALUES (party_id,descr,status,current_user_id);
    RETURNING id INTO new_picking_list_id;
    RETURN new_picking_list_id;
END;
$$ LANGUAGE plpgsql;

--Function to update  picking_list_header
CREATE OR REPLACE FUNCTION wms.update_picking_list_header(
    picking_list_id INT,
    party_id INTEGER,
    descr VARCHAR(255),
    status VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    UPDATE wms.picking_list_header
    SET party_id = party_id,descr = descr,status = status,lub = current_user_id
    WHERE id = picking_list_id;
    RETURN picking_list_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete  picking_list_header
CREATE OR REPLACE FUNCTION wms.delete_picking_list_header(
    picking_list_id_to_delete INT,
    deleted_by_user_id INT
) RETURNS INT AS $$
BEGIN
     --Delete all picking palette associated with this picking header
     PERFORM wms.delete_picking_palette_by_picking_header(picking_list_id_to_delete,deleted_by_user_id);
     --Delete all picking order associated with this picking header
     PERFORM wms.delete_picking_order_by_picking_header(picking_list_id_to_delete,deleted_by_user_id);

    UPDATE wms.picking_list_header
    SET is_active = false,lub = deleted_by_user_id
    WHERE id = picking_list_id_to_delete;
    RETURN picking_list_id_to_delete;
END;
$$ LANGUAGE plpgsql;

---------------------------** Picking List Palette **---------------------------


--Function to insert in picking_list_palette
CREATE OR REPLACE FUNCTION wms.insert_picking_list_palette(
    header_id INTEGER,
    palette_id INTEGER
    item_id INTEGER,
    qty INTEGER,
    descr VARCHAR(255),
    status VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE 
    new_picking_palette_id INT;
BEGIN
    INSERT INTO wms.picking_list_palette(header_id,palette_id,item_id,qty,descr,status,lub)
    VALUES (header_id,palette_id,item_id,qty,descr,status,current_user_id);
    RETURNING id INTO new_picking_palette_id;
    RETURN new_picking_palette_id;
END;
$$ LANGUAGE plpgsql;

--Function to update  picking_list_palette
CREATE OR REPLACE FUNCTION wms.update_picking_list_palette(
    picking_palette_id INT,
    header_id INTEGER,
    palette_id INTEGER,
    item_id INTEGER,
    qty INTEGER,
    descr VARCHAR(255),
    status VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    UPDATE wms.picking_list_palette
    SET header_id = header_id,palette_id = palette_id,item_id = item_id,descr = descr,status = status,lub = current_user_id
    WHERE id = picking_palette_id;
    RETURN picking_palette_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete  picking_list_palette
CREATE OR REPLACE FUNCTION wms.delete_picking_list_palette(
    picking_palette_id_to_delete INT,
    deleted_by_user_id INT
) RETURNS INT AS $$
BEGIN
    UPDATE wms.picking_list_palette
    SET is_active = false,lub = deleted_by_user_id
    WHERE id = picking_palette_id_to_delete;
    RETURN picking_palette_id_to_delete;
END;
$$ LANGUAGE plpgsql;

-- Function to delete all  picking palettes linked to a picking list header
CREATE OR REPLACE FUNCTION wms.delete_picking_palette_by_picking_header(
    header_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNS VOID AS $$
BEGIN
    UPDATE wms.picking_list_palette
    SET is_active = false,lub = deleted_by_user_id
    WHERE header_id = header_id_to_delete;
END;
$$ LANGUAGE plpgsql;

---------------------------** Picking List Order **---------------------------


--Function to insert in picking_list_order
CREATE OR REPLACE FUNCTION wms.insert_picking_list_order(
    header_id INTEGER,
    order_id INTEGER
    item_id INTEGER,
    qty INTEGER,
    descr VARCHAR(255),
    status VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE 
    new_picking_order_id INT;
BEGIN
    INSERT INTO wms.picking_list_order(header_id,order_id,item_id,qty,descr,status,lub)
    VALUES (header_id,order_id,item_id,qty,descr,status,current_user_id);
    RETURNING id INTO new_picking_palette_id;
    RETURN new_picking_palette_id;
END;
$$ LANGUAGE plpgsql;

--Function to update  picking_list_order
CREATE OR REPLACE FUNCTION wms.update_picking_list_order(
    picking_order_id INT,
    header_id INTEGER,
    order_id INTEGER,
    item_id INTEGER,
    qty INTEGER,
    descr VARCHAR(255),
    status VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    UPDATE wms.picking_list_order
    SET header_id = header_id,order_id = order_id,item_id = item_id,descr = descr,status = status,lub = current_user_id
    WHERE id = picking_order_id;
    RETURN picking_order_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete  picking_list_order
CREATE OR REPLACE FUNCTION wms.delete_picking_list_order(
    picking_order_id_to_delete INT,
    deleted_by_user_id INT
) RETURNS INT AS $$
BEGIN
    UPDATE wms.picking_list_order
    SET is_active = false,lub = deleted_by_user_id
    WHERE id = picking_order_id_to_delete;
    RETURN picking_order_id_to_delete;
END;
$$ LANGUAGE plpgsql;

-- Function to delete all picking orders linked to a picking list header
CREATE OR REPLACE FUNCTION wms.delete_picking_order_by_picking_header(
    header_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNS VOID AS $$
BEGIN
    UPDATE wms.picking_list_order
    SET is_active = false,lub = deleted_by_user_id
    WHERE header_id = header_id_to_delete;
END;
$$ LANGUAGE plpgsql;


---------------------------** Palette Master **---------------------------


--Function to insert in palette_master
CREATE OR REPLACE FUNCTION wms.insert_palette_master(
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE 
    new_palette_master_id INT;
BEGIN
    INSERT INTO wms.palette_master(descr,lub)
    VALUES (descr,current_user_id);
    RETURNING id INTO new_palette_id;
    RETURN new_palette_id;
END;
$$ LANGUAGE plpgsql;

--Function to update  palette_master
CREATE OR REPLACE FUNCTION wms.update_palette_master(
    palette_id INT,
    descr VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    UPDATE wms.palette_master
    SET descr = descr,lub = current_user_id
    WHERE id = palette_id;
    RETURN palette_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete  palette_master
CREATE OR REPLACE FUNCTION wms.delete_palette_master(
    palette_id_to_delete INT,
    deleted_by_user_id INT
) RETURNS INT AS $$
BEGIN
    UPDATE wms.palette_master
    SET is_active = false,lub = deleted_by_user_id
    WHERE id = palette_id_to_delete;
    RETURN palette_id_to_delete;
END;
$$ LANGUAGE plpgsql;