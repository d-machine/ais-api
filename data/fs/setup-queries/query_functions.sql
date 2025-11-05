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
    descr VARCHAR(255),
    current_user_id INT
) RETURNS INT AS $$
DECLARE new_role_id INT;
BEGIN
    INSERT INTO administration.role (name, descr, lub)
    VALUES (name, descr, current_user_id)
    RETURNING id INTO new_role_id;
    return new_role_id;
END;
$$ LANGUAGE plpgsql;

-- Update a role
CREATE OR REPLACE FUNCTION administration.update_role(
    role_id INT,
    name VARCHAR(255),
    descr VARCHAR(255),
    current_user_id INT
) RETURNS INT AS $$
BEGIN
    UPDATE administration.role
    SET name = name, descr = descr, lub = current_user_id
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
    INSERT INTO administration.role_history (role_id, name, descr, operation, operation_at, operation_by)
    SELECT id, name, descr, 'DELETE', NOW(), current_user_id
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
-- Function to insert in country
CREATE OR REPLACE FUNCTION wms.insert_country(
    country_name VARCHAR(255),
    country_code VARCHAR(3),
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_country_id INT;
BEGIN
    INSERT INTO wms.country (name, code, descr, lub)
    VALUES (country_name, country_code, descr, current_user_id)
    RETURNING id into new_country_id;
    RETURN new_country_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update country
CREATE OR REPLACE FUNCTION wms.update_country(
    country_id INT,
    country_name VARCHAR(255),
    country_code VARCHAR(3),
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.country
    SET name = country_name, code = country_code, descr = descr, lub = current_user_id
    WHERE id = country_id;
    RETURN country_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete country
CREATE OR REPLACE FUNCTION wms.delete_country(
    country_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS INT AS $$
BEGIN
    -- Delete all states associated with this country
    PERFORM wms.delete_state_by_country(country_id_to_delete, deleted_by_user_id);

    -- Delete country
    UPDATE wms.country
    SET is_active = false, lub = deleted_by_user_id
    WHERE id = country_id_to_delete;
    RETURN country_id_to_delete;
END;
$$ LANGUAGE plpgsql;

---------------------------** State Master **---------------------------

-- Function to insert in state
CREATE OR REPLACE FUNCTION wms.insert_state(
    name VARCHAR(255),
    code VARCHAR(3),
    descr VARCHAR(255),
    country_id INT,
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_state_id INT;
BEGIN
    INSERT INTO wms.state (name, code, descr, country_id, lub)
    VALUES (name, code, descr, country_id, current_user_id)
    RETURNING id into new_state_id;
    RETURN new_state_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update state
CREATE OR REPLACE FUNCTION wms.update_state(
    state_id INT,
    name VARCHAR(255),
    code VARCHAR(3),
    descr VARCHAR(255),
    country_id INT,
    current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.state
    SET name = name, code = code, descr = descr, country_id = country_id, lub = current_user_id
    WHERE id = state_id;
    RETURN state_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete state
CREATE OR REPLACE FUNCTION wms.delete_state(
    state_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    -- Delete state
    UPDATE wms.state
    SET is_active = false, lub = deleted_by_user_id
    WHERE id = state_id_to_delete;
    RETURN state_id_to_delete;
END;
$$ LANGUAGE plpgsql;

-- Function to delete all states associated with a country
CREATE OR REPLACE FUNCTION wms.delete_state_by_country(
    country_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
) RETURNS VOID AS $$
BEGIN
    UPDATE wms.state
    SET is_active = false, lub = deleted_by_user_id
    WHERE country_id = country_id_to_delete;
END;
$$ LANGUAGE plpgsql;


---------------------------** Item Category Master **---------------------------


-- Function to insert in item_category
CREATE OR REPLACE FUNCTION wms.insert_item_category(
    category_name VARCHAR(255),
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_category_id INT;
BEGIN 
    INSERT INTO wms.item_category(name, descr, lub)
    VALUES (category_name, descr, current_user_id)
    RETURNING id INTO new_category_id;
    RETURN new_category_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update item_category
CREATE OR REPLACE FUNCTION wms.update_item_category(
    category_id INT,
    category_name VARCHAR(255),
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.item_category
    SET name = category_name, descr = descr, lub = current_user_id
    WHERE id = category_id;
    RETURN category_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete item_category
CREATE OR REPLACE FUNCTION wms.delete_item_category(
    category_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    -- Delete all brands associated with this item category
    PERFORM wms.delete_item_brand_by_item_category(category_id_to_delete,deleted_by_user_id);

    --Delete item category
    UPDATE wms.item_category
    SET is_active = false, lub = deleted_by_user_id
    WHERE id = category_id_to_delete;
    RETURN category_id_to_delete;
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
DECLARE new_brand_id INT;
BEGIN 
    INSERT INTO wms.item_brand(brand_name,category_id,descr,lub)
    VALUES (brand_name,category_id,descr,current_user_id)
    RETURNING id INTO new_brand_id;
    RETURN new_brand_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update item_brand
CREATE OR REPLACE FUNCTION wms.update_item_brand(
    brand_id INT,
    brand_name VARCHAR(255),
    category_id INTEGER,
    descr VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
BEGIN 
    UPDATE wms.item_brand
    SET brand_name = brand_name,category_id = category_id,descr = descr,lub = current_user_id
    WHERE id = item_brand_id;
    RETURN brand_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete item_brand
CREATE OR REPLACE  FUNCTION wms.delete_item_brand(
    brand_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNS INT AS $$
BEGIN 
    --Delete brand
    UPDATE wms.item_brand
    SET is_active = false ,lub = deleted_by_user_id
    WHERE id = brand_id_to_delete;
    RETURN brand_id_to_delete;
END;
$$ LANGUAGE plpgsql;

-- Function to delete all item_brand associated with an item_category
CREATE OR REPLACE FUNCTION wms.delete_item_brand_by_item_category(
    category_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNS VOID AS $$
BEGIN
    UPDATE wms.item_brand
    SET is_active = false ,lub = deleted_by_user_id
    WHERE category_id = category_id_to_delete;
END;
$$ LANGUAGE plpgsql;

---------------------------** Sales Order Header **---------------------------


-- Function to insert in sales_order_header
CREATE OR REPLACE FUNCTION wms.insert_sales_order_header(
    entry_no VARCHAR(6),
    entry_dt TIMESTAMP,
    party_id INTEGER,
    broker_id INTEGER,
    delivery_at_id INTEGER,
    trsp_id INTEGER,
    year_code VARCHAR(4),
    delivery_dt TIMESTAMP,
    status VARCHAR(255),
    remarks VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_sales_header_id INT;
BEGIN
    INSERT INTO wms.sales_order_header(
        entry_no,
        entry_dt,
        party_id,
        broker_id,
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
        delivery_at_id,
        trsp_id,
        year_code,
        delivery_dt,
        status,
        remarks,
        current_user_id
    )
    RETURNING id INTO new_sales_header_id;
    RETURN new_sales_header_id;
END;
$$ LANGUAGE plpgsql;

--Function to update sales_order_header
CREATE OR  REPLACE FUNCTION wms.update_sales_order_header(
    sales_order_header_id INT,
    entry_no VARCHAR(6),
    entry_dt TIMESTAMP,
    party_id INTEGER,
    broker_id INTEGER,
    delivery_at_id INTEGER,
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
        broker_id = broker_id,
        delivery_at_id = delivery_at_id,
        trsp_id = trsp_id,
        year_code = year_code,
        delivery_dt = delivery_dt,
        status =status,
        remarks = remarks,
        lub = current_user_id
    WHERE id = sales_order_header_id;
    RETURN sales_order_header_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete sales_order_header
CREATE OR REPLACE FUNCTION wms.delete_sales_order_header(
    header_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    --Delete all sales details associated with this sales header
    PERFORM wms.delete_sales_details_by_sales_header(sales_order_header_id_to_delete,deleted_by_user_id);

    -- Delete sales order header
    UPDATE wms.sales_order_header
    SET is_active = false,
        lub = deleted_by_user_id
    WHERE id = sales_order_header_id_to_delete;
    RETURN sales_order_header_id_to_delete;
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
DECLARE new_sales_details_id INT;
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
    RETURNING id INTO new_sales_details_id;
    RETURN new_sales_details_id;
END;
$$ LANGUAGE plpgsql;

--Function to update sales_order_details
CREATE OR REPLACE FUNCTION wms.update_sales_order_details(
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
    WHERE id = sales_order_details_id;
    RETURN sales_order_details_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete sales_order_details
CREATE OR REPLACE FUNCTION wms.delete_sales_order_details(
    sales_order_details_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    --Delete Sales details
    UPDATE wms.sales_order_details
    SET is_active = false,
        lub = deleted_by_user_id
    WHERE id =  sales_order_details_id_to_delete;
    RETURN sales_order_details_id_to_delete;
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
DECLARE new_picking_header_id INT;
BEGIN
    INSERT INTO wms.picking_list_header(party_id,descr,status,lub)
    VALUES (party_id,descr,status,current_user_id)
    RETURNING id INTO new_picking_header_id;
    RETURN new_picking_header_id;
END;
$$ LANGUAGE plpgsql;

--Function to update  picking_list_header
CREATE OR REPLACE FUNCTION wms.update_picking_list_header(
    picking_list_header_id INT,
    party_id INTEGER,
    descr VARCHAR(255),
    status VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    UPDATE wms.picking_list_header
    SET party_id = party_id,descr = descr,status = status,lub = current_user_id
    WHERE id = picking_list_header_id;
    RETURN picking_list_header_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete  picking_list_header
CREATE OR REPLACE FUNCTION wms.delete_picking_list_header(
    picking_list_header_id_to_delete INT,
    deleted_by_user_id INT
) RETURNS INT AS $$
BEGIN
    -- Delete all picking_palette associated with picking header
    PERFORM wms.delete_picking_palette_by_picking_header(picking_list_header_id_to_delete,deleted_by_user_id);
    -- Delete all picking_order associated with picking header
    PERFORM wms.delete_picking_order_by_picking_header(picking_list_header_id_to_delete,deleted_by_user_id);
    
    --Delete picking header
    UPDATE wms.picking_list_header
    SET is_active = false,lub = deleted_by_user_id
    WHERE id = picking_list_header_id_to_delete;
    RETURN picking_list_header_id_to_delete;
END;
$$ LANGUAGE plpgsql;

---------------------------** Picking List Palette **---------------------------


--Function to insert in picking_list_palette
CREATE OR REPLACE FUNCTION wms.insert_picking_list_palette(
    palette_id INTEGER,
    item_id INTEGER,
    qty INTEGER,
    descr VARCHAR(255),
    status VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_picking_palette_id INT;
BEGIN
    INSERT INTO wms.picking_list_palette(header_id,palette_id,item_id,qty,descr,status,lub)
    VALUES (header_id,palette_id,item_id,qty,descr,status,current_user_id)
    RETURNING id INTO new_picking_palette_id;
    RETURN new_picking_palette_id;
END;
$$ LANGUAGE plpgsql;

--Function to update  picking_list_palette
CREATE OR REPLACE FUNCTION wms.update_picking_list_palette(
    picking_list_palette_id INT,
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
    WHERE id = picking_list_palette_id;
    RETURN picking_list_palette_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete  picking_list_palette
CREATE OR REPLACE FUNCTION wms.delete_picking_list_palette(
    picking_palette_id_to_delete INT,
    deleted_by_user_id INT
) RETURNS INT AS $$
BEGIN
    --Delete picking palette
    UPDATE wms.picking_list_palette
    SET is_active = false,lub = deleted_by_user_id
    WHERE id = picking_list_palette_id_to_delete;
    RETURN picking_list_palette_id_to_delete;
END;
$$ LANGUAGE plpgsql;

-- Function to delete all  picking palette associated with picking list header
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
    order_id INTEGER,
    item_id INTEGER,
    qty INTEGER,
    descr VARCHAR(255),
    status VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_picking_order_id INT;
BEGIN
    INSERT INTO wms.picking_list_order(header_id,order_id,item_id,qty,descr,status,lub)
    VALUES (header_id,order_id,item_id,qty,descr,status,current_user_id)
    RETURNING id INTO new_picking_order_id;
    RETURN new_picking_order_id;
END;
$$ LANGUAGE plpgsql;

--Function to update  picking_list_order
CREATE OR REPLACE FUNCTION wms.update_picking_list_order(
    picking_list_order_id INT,
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
    WHERE id = picking_list_order_id;
    RETURN picking_list_order_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete  picking_list_order
CREATE OR REPLACE FUNCTION wms.delete_picking_list_order(
    picking_list_order_id_to_delete INT,
    deleted_by_user_id INT
) RETURNS INT AS $$
BEGIN
    --Delete picking order
    UPDATE wms.picking_list_order
    SET is_active = false,lub = deleted_by_user_id
    WHERE id = picking_list_order_id_to_delete;
    RETURN picking_list_order_id_to_delete;
END;
$$ LANGUAGE plpgsql;

-- Function to delete all picking orders associated with  picking  header
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


--Function to insert in palette
CREATE OR REPLACE FUNCTION wms.insert_palette(
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_palette_id INT;
BEGIN
    INSERT INTO wms.palette(descr,lub)
    VALUES (descr,current_user_id)
    RETURNING id INTO new_palette_id;
    RETURN new_palette_id;
END;
$$ LANGUAGE plpgsql;

--Function to update  palette
CREATE OR REPLACE FUNCTION wms.update_palette(
    palette_id INT,
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.palette
    SET descr = descr,lub = current_user_id
    WHERE id = palette_id;
    RETURN palette_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete  palette
CREATE OR REPLACE FUNCTION wms.delete_palette(
    palette_id_to_delete INT,
    deleted_by_user_id INT
) RETURNS INT AS $$
BEGIN
    UPDATE wms.palette
    SET descr = descr,lub = current_user_id
    WHERE id = palette_id;
    RETURN palette_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete  palette
CREATE OR REPLACE FUNCTION wms.delete_palette(
    palette_id_to_delete INT,
    deleted_by_user_id INT
) RETURNS INT AS $$
BEGIN
    -- Delete palette master
    UPDATE wms.palette
    SET is_active = false,lub = deleted_by_user_id
    WHERE id = palette_id_to_delete;
    RETURN palette_id_to_delete;
END;
$$ LANGUAGE plpgsql;


---------------------------** Purchase Order Header **---------------------------


-- Function to insert in purchase_order_header
CREATE OR REPLACE FUNCTION wms.insert_purchase_order_header(
    entry_no VARCHAR(6),
    entry_dt TIMESTAMP,
    party_id INTEGER,
    broker_id INTEGER,
    delivery_at_id INTEGER,
    trsp_id INTEGER,
    year_code VARCHAR(4),
    delivery_dt TIMESTAMP,
    status VARCHAR(255),
    remarks VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_purchase_header_id INT;
BEGIN
    INSERT INTO wms.purchase_order_header(
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
        delivery_at_id,
        trsp_id,
        year_code,
        delivery_dt,
        status,
        remarks,
        current_user_id
    )
    RETURNING id INTO new_purchase_header_id;
    RETURN new_purchase_header_id;
END;
$$ LANGUAGE plpgsql;

--Function to update purchase_order_header
CREATE OR  REPLACE FUNCTION wms.update_purchase_order_header(
    purchase_list_header_id INT,
    entry_no VARCHAR(6),
    entry_dt TIMESTAMP,
    party_id INTEGER,
    broker_id INTEGER,
    delivery_at_id INTEGER,
    trsp_id INTEGER,
    year_code VARCHAR(4),
    delivery_dt TIMESTAMP,
    status VARCHAR(255),
    remarks VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    UPDATE  wms.purchase_order_header
    SET entry_no = entry_no,
        entry_dt = entry_dt,
        party_id = party_id,
        delivery_at_id = delivery_at_id,
        trsp_id = trsp_id,
        year_code = year_code,
        delivery_dt = delivery_dt,
        status =status,
        remarks = remarks,
        lub = current_user_id
    WHERE id = purchase_list_header_id;
    RETURN purchase_list_header_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete purchase_order_header
CREATE OR REPLACE FUNCTION wms.delete_purchase_order_header(
    purchase_list_header_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNs INT AS $$
BEGIN
    --Delete all purchase details associated with this purchase header
    PERFORM wms.delete_purchase_details_by_purchase_header(purchase_list_header_id_to_delete,deleted_by_user_id);

    -- Delete purchase order header
    UPDATE wms.purchase_order_header
    SET is_active = false,
        lub = deleted_by_user_id
    WHERE id = purchase_list_header_id_to_delete;
    RETURN purchase_list_header_id_to_delete;
END;
$$ LANGUAGE plpgsql;


---------------------------** Purchase Order Details **---------------------------


--Function to insert in purchase_order_details
CREATE OR REPLACE FUNCTION wms.insert_purchase_order_details(
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
DECLARE new_purchase_details_id INT;
BEGIN
    INSERT INTO wms.purchase_order_details(
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
    RETURNING id INTO new_purchase_details_id;
    RETURN new_purchase_details_id;
END;
$$ LANGUAGE plpgsql;

--Function to update sales_order_details
CREATE OR REPLACE FUNCTION wms.update_purchase_order_details(
    purchase_order_details_id INTEGER,
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
    UPDATE wms.purchase_order_details
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
    WHERE id = purchase_order_details_id;
    RETURN purchase_order_details_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete purchase_order_details
CREATE OR REPLACE FUNCTION wms.delete_purchase_order_details(
    purchase_order_details_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    --Delete Purchase details
    UPDATE wms.purchase_order_details
    SET is_active = false,
        lub = deleted_by_user_id
    WHERE id =  purchase_order_details_id_to_delete;
    RETURN purchase_order_details_id_to_delete;
END;
$$ LANGUAGE plpgsql;

--Function to delete all purchase details associated with purchase header
CREATE OR REPLACE FUNCTION wms.delete_purchase_details_by_purchase_header(
    header_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNS VOID AS $$
BEGIN 
    UPDATE wms.purchase_order_details
    SET is_active = false,
    lub = deleted_by_user_id
    WHERE header_id = header_id_to_delete;
END;
$$ LANGUAGE plpgsql;


---------------------------** Address **---------------------------

-- Function to insert in address
CREATE OR REPLACE FUNCTION wms.insert_address(
    adr1 VARCHAR(255),
    adr2 VARCHAR(255),
    adr3 VARCHAR(255),
    country_id INTEGER,
    state_id INTEGER,
    city_district_id INTEGER,
    current_user_id INTEGER
)RETURNS INT AS $$
DECLARE new_address_id INT;
BEGIN
    INSERT INTO wms.address (adr1, adr2, adr3, country_id, state_id, city_district_id, lub)
    VALUES (adr1, adr2, adr3, country_id, state_id, city_district_id, current_user_id)
    RETURNING id INTO new_address_id;
    RETURN new_address_id;
END;
$$ LANGUAGE plpgsql;

--Function to update address
CREATE OR REPLACE FUNCTION wms.update_address(
    address_id INT,
    adr1 VARCHAR(255),
    adr2 VARCHAR(255),
    adr3 VARCHAR(255),
    country_id INTEGER,
    state_id INTEGER,
    city_district_id INTEGER,
    current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.address
    SET adr1 = adr1,
        adr2 = adr2,
        adr3 = adr3,
        country_id = country_id,
        state_id = state_id,
        city_district_id = city_district_id,
        lub = current_user_id
    WHERE id = address_id;
    RETURN address_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete address
CREATE OR REPLACE FUNCTION wms.delete_address(
    address_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS INT AS $$
BEGIN
    -- Delete address
    UPDATE wms.address
    SET is_active = false, lub = deleted_by_user_id
    WHERE id = address_id_to_delete;
    RETURN address_id_to_delete;
END;
$$ LANGUAGE plpgsql;


---------------------------** City  Master **---------------------------


-- Function to insert in city
CREATE OR REPLACE FUNCTION wms.insert_city(
    city_name VARCHAR(100),
    city_code VARCHAR(3),
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_city_id INT;
BEGIN
    INSERT INTO wms.city (name, code, descr, lub)
    VALUES (city_name, city_code, descr, current_user_id)
    RETURNING id INTO new_city_id;
    RETURN new_city_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update city
CREATE OR REPLACE FUNCTION wms.update_city(
    city_id INT,
    city_name VARCHAR(100),
    city_code VARCHAR(3),
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.city
    SET name = city_name,
        code = city_code,
        descr = descr,
        lub = current_user_id
    WHERE id = city_id;
    RETURN city_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete city
CREATE OR REPLACE FUNCTION wms.delete_city(
    city_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS INT AS $$
BEGIN 
    -- Delete City
    UPDATE wms.city
    SET is_active = false, lub = deleted_by_user_id
    WHERE id = city_id_to_delete;
    RETURN city_id_to_delete;
END;
$$ LANGUAGE plpgsql;


---------------------------** District Master **---------------------------


CREATE OR REPLACE FUNCTION wms.insert_district(
    district_name VARCHAR(100),
    district_code VARCHAR(3),
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_district_id INT;
BEGIN 
    INSERT INTO wms.district (name, code, descr, lub)
    VALUES (district_name, district_code, descr, current_user_id)
    RETURNING id INTO new_district_id;
    RETURN new_district_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update district
CREATE OR REPLACE FUNCTION wms.update_district(
    district_id INT,
    district_name VARCHAR(100),
    district_code VARCHAR(3),
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.district
    SET name = district_name,
        code = district_code,
        descr = descr,
        lub = current_user_id
    WHERE id = district_id;
    RETURN district_id;
END;
$$ LANGUAGE plpgsql;

-- Funtion to delete district
CREATE OR REPLACE FUNCTION wms.delete_district(
    district_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS INT AS $$
BEGIN
    UPDATE wms.district
    SET is_active = false, lub = deleted_by_user_id
    WHERE id = district_id_to_delete;
    RETURN district_id_to_delete;
END;
$$ LANGUAGE plpgsql;


--------------------------** City District Master **---------------------------

-- Function to insert in city_district
CREATE OR REPLACE FUNCTION wms.insert_city_district(
    name VARCHAR(255),
    city_id INT,
    district_id INT,
    state_id INT,
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_city_district_id INT;
BEGIN
    INSERT INTO wms.city_district (name, city_id, district_id, state_id, descr, lub)
    VALUES (name, city_id, district_id, state_id, descr, current_user_id)
    RETURNING id INTO new_city_district_id;
    RETURN new_city_district_id;
END;
$$ LANGUAGE plpgsql;


-- Function to update city_district
CREATE OR REPLACE FUNCTION wms.update_city_district(
    city_district_id INT,
    name VARCHAR(255),
    city_id INT,
    district_id INT,
    state_id INT,
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.city_district
    SET name = name,
        city_id = city_id,
        district_id = district_id,
        state_id = state_id,
        descr = descr,
        lub = current_user_id,
        lua = NOW()
    WHERE id = city_district_id;
    RETURN city_district_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete city_district 
CREATE OR REPLACE FUNCTION wms.delete_city_district(
    city_district_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.city_district
    SET is_active = false,
        lub = deleted_by_user_id
    WHERE id = city_district_id_to_delete;

    RETURN city_district_id_to_delete;
END;
$$ LANGUAGE plpgsql;

-- Function to delete all city_district by state
CREATE OR REPLACE FUNCTION wms.delete_city_district_by_state(
    state_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
) RETURNS VOID AS $$
BEGIN
    UPDATE wms.city_district
    SET is_active = false,
        lub = deleted_by_user_id
    WHERE state_id = state_id_to_delete;
END;
$$ LANGUAGE plpgsql;

---------------------------** Party Master **---------------------------

-- Function to insert party
CREATE OR REPLACE FUNCTION wms.insert_party(
    party_type VARCHAR(50),
    name VARCHAR(50),
    add1 VARCHAR(50),
    add2 VARCHAR(50),
    add3 VARCHAR(50),
    city VARCHAR(50),
    pincode VARCHAR(50),
    person_name VARCHAR(50),
    telephone VARCHAR(50),
    email VARCHAR(50),
    udate VARCHAR(50),
    salesman VARCHAR(50),
    pan_no VARCHAR(50),
    cr_limit NUMERIC,
    cr_days INTEGER,
    gstno VARCHAR(50),
    aadhar_no VARCHAR(50),
    sales_head VARCHAR(50),
    director VARCHAR(50),
    manager VARCHAR(50),
    city_district_id INTEGER,
    state_id INTEGER,
    country_id INTEGER,
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_party_id INT;
BEGIN
    INSERT INTO wms.party (
        party_type,
        name, 
        add1, 
        add2, 
        add3, 
        city, 
        pincode, 
        person_name,
        telephone, 
        email, 
        udate, 
        salesman, 
        pan_no, 
        cr_limit, 
        cr_days, 
        gstno,
        aadhar_no, 
        sales_head, 
        director, 
        manager, 
        city_district_id,
        state_id,
        country_id,
        lub
    )
    VALUES (
        party_type, 
        name, 
        add1, 
        add2, 
        add3, 
        city, 
        pincode, 
        person_name,
        telephone, 
        email, 
        udate, 
        salesman, 
        pan_no, 
        cr_limit, 
        cr_days, 
        gstno, 
        aadhar_no, 
        sales_head, 
        director, 
        manager, 
        city_district_id,
        state_id,
        country_id,
        current_user_id
    )
    RETURNING id INTO new_party_id;

    RETURN new_party_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update party

CREATE OR REPLACE FUNCTION wms.update_party(
    party_id INT,
    party_type VARCHAR(50),
    name VARCHAR(50),
    add1 VARCHAR(50),
    add2 VARCHAR(50),
    add3 VARCHAR(50),
    city VARCHAR(50),
    pincode VARCHAR(50),
    person_name VARCHAR(50),
    telephone VARCHAR(50),
    email VARCHAR(50),
    udate VARCHAR(50),
    salesman VARCHAR(50),
    pan_no VARCHAR(50),
    cr_limit NUMERIC,
    cr_days INTEGER,
    gstno VARCHAR(50),
    aadhar_no VARCHAR(50),
    sales_head VARCHAR(50),
    director VARCHAR(50),
    manager VARCHAR(50),
    city_district_id INTEGER,
    state_id INTEGER,
    country_id INTEGER,
    current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.party
    SET party_type = party_type,
        name = name,
        add1 = add1,
        add2 = add2,
        add3 = add3,
        city = city,
        pincode = pincode,
        person_name = person_name,
        telephone = telephone,
        email = email,
        udate = udate,
        salesman = salesman,
        pan_no = pan_no,
        cr_limit = cr_limit,
        cr_days = cr_days,
        gstno = gstno,
        country_id = country_id,
        aadhar_no = aadhar_no,
        sales_head = sales_head,
        director = director,
        manager = manager,
        city_district_id = city_district_id,
        state_id = state_id,
        country_id = country_id,
        lub = current_user_id
    WHERE id = party_id;

    RETURN party_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete party
CREATE OR REPLACE FUNCTION wms.delete_party(
    party_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS INT  AS $$
BEGIN
    -- Delete party
    UPDATE wms.party
    SET is_active = false, lub = deleted_by_user_id
    WHERE id = party_id_to_delete;
    RETURN party_id_to_delete;
END;
$$ LANGUAGE plpgsql;


---------------------------** Transport Master **--------------------------

-- Function to insert in transport
CREATE OR REPLACE FUNCTION wms.insert_transport(
    transport_name VARCHAR(255),
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_transport_id INT;
BEGIN
    INSERT INTO wms.transport (name, descr, lub)
    VALUES (transport_name, descr, current_user_id)
    RETURNING id INTO new_transport_id;
    RETURN new_transport_id;
END;
$$ LANGUAGE plpgsql;


-- Function to update transport
CREATE OR REPLACE FUNCTION wms.update_transport(
    transport_id INT,
    transport_name VARCHAR(255),
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.transport
    SET name = transport_name,
        descr = descr,
        lub = current_user_id
    WHERE id = transport_id;
    RETURN transport_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete transport
CREATE OR REPLACE FUNCTION wms.delete_transport(
    transport_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
) 
RETURNS INT AS $$
BEGIN
    -- delete transport
    UPDATE wms.transport
    SET is_active = false,
        lub = deleted_by_user_id
    WHERE id = transport_id;
    RETURN transpory_id_to_delete;
END;
$$ LANGUAGE plpgsql;


---------------------------** UOM  Master **--------------------------

-- Function to insert in UOM
CREATE OR REPLACE FUNCTION wms.insert_uom(
    uom_name VARCHAR(255),
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_uom_id INT;
BEGIN
    INSERT INTO wms.uom (name, descr, lub)
    VALUES (uom_name, descr, current_user_id)
    RETURNING id INTO new_uom_id;
    RETURN new_uom_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update  UOM
CREATE OR REPLACE FUNCTION wms.update_uom(
    uom_id INT,
    uomname VARCHAR(255),
    descr VARCHAR(255),
    current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.uom
    SET name = uom_name,
        descr = descr,
        lub = current_user_id
    WHERE id = uom_id;
    RETURN uom_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete  UOM
CREATE OR REPLACE FUNCTION wms.delete_uom(
    uom_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS INT AS $$
BEGIN
    UPDATE wms.uom
    SET is_active = false,
        lub = deleted_by_user_id
    WHERE id = uom_id_to_delete;
    RETURN uom_id_to_delete;
END;
$$ LANGUAGE plpgsql;


---------------------------** vendor Master **---------------------------

-- Function to insert vendor
CREATE OR REPLACE FUNCTION wms.insert_vendor(
    vendor_type VARCHAR(50),
    name VARCHAR(50),
    add1 VARCHAR(50),
    add2 VARCHAR(50),
    add3 VARCHAR(50),
    city VARCHAR(50),
    pincode VARCHAR(50),
    person_name VARCHAR(50),
    telephone VARCHAR(50),
    email VARCHAR(50),
    udate VARCHAR(50),
    salesman VARCHAR(50),
    pan_no VARCHAR(50),
    cr_limit NUMERIC,
    cr_days INTEGER,
    gstno VARCHAR(50),
    aadhar_no VARCHAR(50),
    sales_head VARCHAR(50),
    director VARCHAR(50),
    manager VARCHAR(50),
    city_district_id INTEGER,
    state_id INTEGER,
    country_id INTEGER,
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_vendor_id INT;
BEGIN
    INSERT INTO wms.vendor (
        vendor_type,
        name, 
        add1, 
        add2, 
        add3, 
        city, 
        pincode, 
        person_name,
        telephone, 
        email, 
        udate, 
        salesman, 
        pan_no, 
        cr_limit, 
        cr_days, 
        gstno,
        aadhar_no, 
        sales_head, 
        director, 
        manager, 
        city_district_id,
        state_id,
        country_id,
        lub
    )
    VALUES (
        vendor_type, 
        name, 
        add1, 
        add2, 
        add3, 
        city, 
        pincode, 
        person_name,
        telephone, 
        email, 
        udate, 
        salesman, 
        pan_no, 
        cr_limit, 
        cr_days, 
        gstno, 
        aadhar_no, 
        sales_head, 
        director, 
        manager, 
        city_district_id,
        state_id,
        country_id,
        current_user_id
    )
    RETURNING id INTO new_vendor_id;

    RETURN new_vendor_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update vendor

CREATE OR REPLACE FUNCTION wms.update_vendor(
    vendor_id INT,
    vendor_type VARCHAR(50),
    name VARCHAR(50),
    add1 VARCHAR(50),
    add2 VARCHAR(50),
    add3 VARCHAR(50),
    city VARCHAR(50),
    pincode VARCHAR(50),
    person_name VARCHAR(50),
    telephone VARCHAR(50),
    email VARCHAR(50),
    udate VARCHAR(50),
    salesman VARCHAR(50),
    pan_no VARCHAR(50),
    cr_limit NUMERIC,
    cr_days INTEGER,
    gstno VARCHAR(50),
    aadhar_no VARCHAR(50),
    sales_head VARCHAR(50),
    director VARCHAR(50),
    manager VARCHAR(50),
    city_district_id INTEGER,
    state_id INTEGER,
    country_id INTEGER,
    current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.vendor
    SET vendor_type = vendor_type,
        name = name,
        add1 = add1,
        add2 = add2,
        add3 = add3,
        city = city,
        pincode = pincode,
        person_name = person_name,
        telephone = telephone,
        email = email,
        udate = udate,
        salesman = salesman,
        pan_no = pan_no,
        cr_limit = cr_limit,
        cr_days = cr_days,
        gstno = gstno,
        country_id = country_id,
        aadhar_no = aadhar_no,
        sales_head = sales_head,
        director = director,
        manager = manager,
        city_district_id = city_district_id,
        state_id = state_id,
        country_id = country_id,
        lub = current_user_id
    WHERE id = vendor_id;

    RETURN vendor_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete vendor
CREATE OR REPLACE FUNCTION wms.delete_vendor(
    vendor_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS INT  AS $$
BEGIN
    -- Delete vendor
    UPDATE wms.vendor
    SET is_active = false, lub = deleted_by_user_id
    WHERE id = vendor_id_to_delete;
    RETURN vendor_id_to_delete;
END;
$$ LANGUAGE plpgsql;


---------------------------** Broker Master **---------------------------

-- Function to insert broker
CREATE OR REPLACE FUNCTION wms.insert_broker(
    broker_type VARCHAR(50),
    name VARCHAR(50),
    add1 VARCHAR(50),
    add2 VARCHAR(50),
    add3 VARCHAR(50),
    city VARCHAR(50),
    pincode VARCHAR(50),
    person_name VARCHAR(50),
    telephone VARCHAR(50),
    email VARCHAR(50),
    udate VARCHAR(50),
    salesman VARCHAR(50),
    pan_no VARCHAR(50),
    cr_limit NUMERIC,
    cr_days INTEGER,
    gstno VARCHAR(50),
    aadhar_no VARCHAR(50),
    sales_head VARCHAR(50),
    director VARCHAR(50),
    manager VARCHAR(50),
    city_district_id INTEGER,
    state_id INTEGER,
    country_id INTEGER,
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_broker_id INT;
BEGIN
    INSERT INTO wms.broker (
        broker_type,
        name, 
        add1, 
        add2, 
        add3, 
        city, 
        pincode, 
        person_name,
        telephone, 
        email, 
        udate, 
        salesman, 
        pan_no, 
        cr_limit, 
        cr_days, 
        gstno,
        aadhar_no, 
        sales_head, 
        director, 
        manager, 
        city_district_id,
        state_id,
        country_id,
        lub
    )
    VALUES (
        broker_type, 
        name, 
        add1, 
        add2, 
        add3, 
        city, 
        pincode, 
        person_name,
        telephone, 
        email, 
        udate, 
        salesman, 
        pan_no, 
        cr_limit, 
        cr_days, 
        gstno, 
        aadhar_no, 
        sales_head, 
        director, 
        manager, 
        city_district_id,
        state_id,
        country_id,
        current_user_id
    )
    RETURNING id INTO new_broker_id;

    RETURN new_broker_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update broker

CREATE OR REPLACE FUNCTION wms.update_broker(
    broker_id INT,
    broker_type VARCHAR(50),
    name VARCHAR(50),
    add1 VARCHAR(50),
    add2 VARCHAR(50),
    add3 VARCHAR(50),
    city VARCHAR(50),
    pincode VARCHAR(50),
    person_name VARCHAR(50),
    telephone VARCHAR(50),
    email VARCHAR(50),
    udate VARCHAR(50),
    salesman VARCHAR(50),
    pan_no VARCHAR(50),
    cr_limit NUMERIC,
    cr_days INTEGER,
    gstno VARCHAR(50),
    aadhar_no VARCHAR(50),
    sales_head VARCHAR(50),
    director VARCHAR(50),
    manager VARCHAR(50),
    city_district_id INTEGER,
    state_id INTEGER,
    country_id INTEGER,
    current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.broker
    SET broker_type = broker_type,
        name = name,
        add1 = add1,
        add2 = add2,
        add3 = add3,
        city = city,
        pincode = pincode,
        person_name = person_name,
        telephone = telephone,
        email = email,
        udate = udate,
        salesman = salesman,
        pan_no = pan_no,
        cr_limit = cr_limit,
        cr_days = cr_days,
        gstno = gstno,
        country_id = country_id,
        aadhar_no = aadhar_no,
        sales_head = sales_head,
        director = director,
        manager = manager,
        city_district_id = city_district_id,
        state_id = state_id,
        country_id = country_id,
        lub = current_user_id
    WHERE id = broker_id;

    RETURN broker_id;
END;
$$ LANGUAGE plpgsql;

--Function to delete broker
CREATE OR REPLACE FUNCTION wms.delete_broker(
    broker_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS INT  AS $$
BEGIN
    -- Delete broker
    UPDATE wms.broker
    SET is_active = false, lub = deleted_by_user_id
    WHERE id = broker_id_to_delete;
    RETURN broker_id_to_delete;
END;
$$ LANGUAGE plpgsql;


---------------------------** Material Master **---------------------------

-- Function to insert in  material
CREATE OR REPLACE FUNCTION wms.insert_material(
    material_name VARCHAR(255),
    descr VARCHAR(255),
    brand_id INT,
    uom_pc_id INT,
    uom_package_id INT,
    pc_in_package NUMERIC,
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_material_id INT;
BEGIN
    INSERT INTO wms.material (name, descr, brand_id, uom_pc_id, uom_package_id, pc_in_package, lub)
    VALUES (material_name, descr, brand_id, uom_pc_id, uom_package_id, pc_in_package, current_user_id)
    RETURNING id INTO new_material_id;
    RETURN new_material_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update a material
CREATE OR REPLACE FUNCTION wms.update_material(
    material_id INT,
    material_name VARCHAR(255),
    descr VARCHAR(255),
    brand_id INT,
    uom_pc_id INT,
    uom_package_id INT,
    pc_in_package NUMERIC,
    current_user_id INT
) RETURNS INT AS $$
BEGIN
    UPDATE wms.material
    SET name = material_name,
        descr = descr,
        brand_id = brand_id,
        uom_pc_id = uom_pc_id,
        uom_package_id = uom_package_id,
        pc_in_package = pc_in_package,
        lub = current_user_id
    WHERE id = material_id;
    RETURN material_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete material
CREATE OR REPLACE FUNCTION wms.delete_material(
    material_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.material
    SET is_active = false,
        lub = deleted_by_user_id
    WHERE id = material_id_to_delete;
    RETURN material_id_to_delete;
END;
$$ LANGUAGE plpgsql;


