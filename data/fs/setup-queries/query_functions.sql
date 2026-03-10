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
    _country_id INT,
    _country_name VARCHAR(255),
    _country_code VARCHAR(3),
    _descr VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.country
    SET name = _country_name, code = _country_code, descr = _descr, lub = _current_user_id
    WHERE id = _country_id;
    RETURN _country_id;
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
    code INTEGER,
    descr VARCHAR(255),
    country_id INT,
    state_type VARCHAR(5),
    current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_state_id INT;
BEGIN
    INSERT INTO wms.state (name, code, descr, country_id, state_type, lub)
    VALUES (name, code, descr, country_id, state_type, current_user_id)
    RETURNING id into new_state_id;
    RETURN new_state_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update state
CREATE OR REPLACE FUNCTION wms.update_state(
    _state_id INT,
    _name VARCHAR(255),
    _code INTEGER,
    _descr VARCHAR(255),
    _country_id INT,
    _state_type VARCHAR(5),
    _current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.state
    SET name = _name, code = _code, descr = _descr, country_id = _country_id, state_type = _state_type, lub = _current_user_id
    WHERE id = _state_id;
    RETURN _state_id;
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
DECLARE
    city_ids_to_delete INTEGER[];
    district_ids_to_delete INTEGER[];
BEGIN
    -- Get all city IDs that are mapped to states in this country
    SELECT ARRAY_AGG(DISTINCT city_id) INTO city_ids_to_delete
    FROM wms.city_district
    WHERE state_id IN (
        SELECT id FROM wms.state WHERE country_id = country_id_to_delete
    ) AND is_active = true;
    
    -- Get all district IDs that are mapped to states in this country
    SELECT ARRAY_AGG(DISTINCT district_id) INTO district_ids_to_delete
    FROM wms.city_district
    WHERE state_id IN (
        SELECT id FROM wms.state WHERE country_id = country_id_to_delete
    ) AND is_active = true;
    
    -- Delete all city_district mappings for states in this country
    UPDATE wms.city_district
    SET is_active = false, lub = deleted_by_user_id
    WHERE state_id IN (
        SELECT id FROM wms.state WHERE country_id = country_id_to_delete
    );
    
    -- Delete cities that were in the mappings
    IF city_ids_to_delete IS NOT NULL THEN
        UPDATE wms.city
        SET is_active = false, lub = deleted_by_user_id
        WHERE id = ANY(city_ids_to_delete);
    END IF;
    
    -- Delete districts that were in the mappings
    IF district_ids_to_delete IS NOT NULL THEN
        UPDATE wms.district
        SET is_active = false, lub = deleted_by_user_id
        WHERE id = ANY(district_ids_to_delete);
    END IF;
    
    -- Delete all states
    UPDATE wms.state
    SET is_active = false, lub = deleted_by_user_id
    WHERE country_id = country_id_to_delete;
END;
$$ LANGUAGE plpgsql;


---------------------------** Item Category Master **---------------------------


-- Function to insert in item_category
CREATE OR REPLACE FUNCTION wms.insert_item_category(
    item_category_name VARCHAR(255),
    descr VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
DECLARE new_item_category_id INT;
BEGIN 
    INSERT INTO wms.item_category(name,descr,lub)
    VALUES (item_category_name,descr,current_user_id)
    RETURNING id INTO new_item_category_id;
    RETURN new_item_category_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update item_category
CREATE OR REPLACE FUNCTION wms.update_item_category(
    _item_category_id INT,
    _item_category_name VARCHAR(255),
    _descr VARCHAR(255),
    _current_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    UPDATE wms.item_category
    SET name = _item_category_name, descr = _descr, lub = _current_user_id
    WHERE id = _item_category_id;
    RETURN _item_category_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete item_category
CREATE OR REPLACE FUNCTION wms.delete_item_category(
    item_category_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    -- Delete all brands associated with this item category
    PERFORM wms.delete_item_brand_by_item_category(item_category_id_to_delete,deleted_by_user_id);

    --Delete item category
    UPDATE wms.item_category
    SET is_active = false,lub = deleted_by_user_id
    WHERE id = item_category_id_to_delete;
    RETURN item_category_id_to_delete;
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
    _item_brand_id INT,
    _brand_name VARCHAR(255),
    _category_id INTEGER,
    _descr VARCHAR(255),
    _current_user_id INTEGER
)RETURNS INT AS $$
BEGIN 
    UPDATE wms.item_brand
    SET brand_name = _brand_name, category_id = _category_id, descr = _descr, lub = _current_user_id
    WHERE id = _item_brand_id;
    RETURN _item_brand_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete item_brand
CREATE OR REPLACE  FUNCTION wms.delete_item_brand(
    item_brand_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)RETURNS INT AS $$
BEGIN 
    --Delete brand
    UPDATE wms.item_brand
    SET is_active = false ,lub = deleted_by_user_id
    WHERE id = item_brand_id_to_delete;
    RETURN item_brand_id_to_delete;
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

---------------------------** UOM Conversion Master **---------------------------

-- Function to insert UOM conversion
CREATE OR REPLACE FUNCTION wms.insert_uom_conversion(
    _uom_id_each INTEGER,
    _uom_id_case INTEGER,
    _no_of_pcs NUMERIC,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _id INTEGER;
BEGIN
    INSERT INTO wms.uom_conversion (uom_id_each, uom_id_case, no_of_pcs, lub)
    VALUES (_uom_id_each, _uom_id_case, _no_of_pcs, _current_user_id)
    RETURNING id INTO _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to update UOM conversion
CREATE OR REPLACE FUNCTION wms.update_uom_conversion(
    _id INTEGER,
    _uom_id_each INTEGER,
    _uom_id_case INTEGER,
    _no_of_pcs NUMERIC,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.uom_conversion
    SET uom_id_each = _uom_id_each,
        uom_id_case = _uom_id_case,
        no_of_pcs = _no_of_pcs,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete UOM conversion (soft delete)
CREATE OR REPLACE FUNCTION wms.delete_uom_conversion(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.uom_conversion
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

---------------------------** Material Master **---------------------------

-- Function to insert material
CREATE OR REPLACE FUNCTION wms.insert_material(
    _name VARCHAR(255),
    _descr VARCHAR(255),
    _category_id INTEGER,
    _brand_id INTEGER,
    _hsn_id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _id INTEGER;
BEGIN
    INSERT INTO wms.material (
        name, descr, category_id, brand_id, hsn_id, lub
    )
    VALUES (
        _name, _descr, _category_id, _brand_id, _hsn_id, _current_user_id
    )
    RETURNING id INTO _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to update material
CREATE OR REPLACE FUNCTION wms.update_material(
    _id INTEGER,
    _name VARCHAR(255),
    _descr VARCHAR(255),
    _category_id INTEGER,
    _brand_id INTEGER,
    _hsn_id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.material
    SET name = _name,
        descr = _descr,
        category_id = _category_id,
        brand_id = _brand_id,
        hsn_id = _hsn_id,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete material (soft delete)
CREATE OR REPLACE FUNCTION wms.delete_material(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.material_ean
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE material_id = _id AND is_active = true;

    UPDATE wms.material
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

---------------------------** Material EAN **---------------------------

-- Function to insert material EAN
CREATE OR REPLACE FUNCTION wms.insert_material_ean(
    p_material_id INTEGER,
    p_ean_code VARCHAR(100),
    p_label VARCHAR(255),
    p_uom_pc_id INTEGER,
    p_uom_package_id INTEGER,
    p_mrp DECIMAL(15,2),
    p_selling_rate DECIMAL(15,2),
    p_current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _id INTEGER;
BEGIN
    INSERT INTO wms.material_ean (
        material_id, ean_code, label, uom_pc_id, uom_package_id, mrp, selling_rate, lub
    )
    VALUES (
        p_material_id, p_ean_code, p_label, p_uom_pc_id, p_uom_package_id, p_mrp, p_selling_rate, p_current_user_id
    )
    RETURNING id INTO _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to update material EAN
CREATE OR REPLACE FUNCTION wms.update_material_ean(
    p_id INTEGER,
    p_material_id INTEGER,
    p_ean_code VARCHAR(100),
    p_label VARCHAR(255),
    p_uom_pc_id INTEGER,
    p_uom_package_id INTEGER,
    p_mrp DECIMAL(15,2),
    p_selling_rate DECIMAL(15,2),
    p_current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.material_ean
    SET material_id = p_material_id,
        ean_code = p_ean_code,
        label = p_label,
        uom_pc_id = p_uom_pc_id,
        uom_package_id = p_uom_package_id,
        mrp = p_mrp,
        selling_rate = p_selling_rate,
        lub = p_current_user_id,
        lua = NOW()
    WHERE id = p_id;
    RETURN p_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete material EAN (soft delete)
CREATE OR REPLACE FUNCTION wms.delete_material_ean(
    p_id INTEGER,
    p_current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.material_ean
    SET is_active = false, lub = p_current_user_id, lua = NOW()
    WHERE id = p_id;
    RETURN p_id;
END;
$$ LANGUAGE plpgsql;

---------------------------** Sales Order Header **---------------------------


-- Function to insert in sales_order_header
CREATE OR REPLACE FUNCTION wms.insert_sales_order_header(
    entry_dt TIMESTAMP,
    party_id INTEGER,
    broker_id INTEGER,
    delivery_at_id INTEGER,
    trsp_id INTEGER,
    delivery_dt TIMESTAMP,
    status VARCHAR(255),
    remarks VARCHAR(255),
    current_user_id INTEGER
) RETURNS TABLE (id INTEGER, entry_no VARCHAR) AS $$
DECLARE
    new_sales_header_id INT;
    new_entry_no VARCHAR(6);
    max_entry_no INT;
    _year_code VARCHAR(4);
BEGIN
    -- Compute fiscal year (April-based)
    _year_code := CASE
        WHEN EXTRACT(MONTH FROM CURRENT_DATE) >= 4
        THEN TO_CHAR(CURRENT_DATE, 'YYYY')
        ELSE TO_CHAR(CURRENT_DATE - INTERVAL '1 year', 'YYYY')
    END;

    -- Auto-generate entry_no
    SELECT COALESCE(MAX(CAST(sh.entry_no AS INTEGER)), 0) INTO max_entry_no
    FROM wms.sales_order_header sh;

    new_entry_no := LPAD((max_entry_no + 1)::TEXT, 6, '0');

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
        new_entry_no,
        entry_dt,
        party_id,
        broker_id,
        delivery_at_id,
        trsp_id,
        _year_code,
        delivery_dt,
        status,
        remarks,
        current_user_id
    )
    RETURNING wms.sales_order_header.id INTO new_sales_header_id;

    RETURN QUERY SELECT new_sales_header_id, new_entry_no;
END;
$$ LANGUAGE plpgsql;

-- Function to update sales_order_header
CREATE OR REPLACE FUNCTION wms.update_sales_order_header(
    _id INTEGER,
    _entry_dt TIMESTAMP,
    _party_id INTEGER,
    _broker_id INTEGER,
    _delivery_at_id INTEGER,
    _trsp_id INTEGER,
    _delivery_dt TIMESTAMP,
    _status VARCHAR(255),
    _remarks VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.sales_order_header
    SET entry_dt = _entry_dt,
        party_id = _party_id,
        broker_id = _broker_id,
        delivery_at_id = _delivery_at_id,
        trsp_id = _trsp_id,
        delivery_dt = _delivery_dt,
        status = _status,
        remarks = _remarks,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete sales_order_header
CREATE OR REPLACE FUNCTION wms.delete_sales_order_header(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.sales_order_header
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    
    -- Also delete details
    UPDATE wms.sales_order_details
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE header_id = _id;
    
    RETURN _id;
END;
$$ LANGUAGE plpgsql;


---------------------------** Sales Order Details **---------------------------

-- Function to insert sales_order_details
CREATE OR REPLACE FUNCTION wms.insert_sales_order_details(
    _header_id INTEGER,
    _item_id INTEGER,
    _euom INTEGER,
    _puom INTEGER,
    _quom INTEGER,
    _rate_per_pc DECIMAL(15,2),
    _eqty DECIMAL(15,3),
    _pqty DECIMAL(15,3),
    _amount DECIMAL(15,2),
    _dqty DECIMAL(15,3),
    _status VARCHAR(255),
    _remarks VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _id INTEGER;
    _entry_no VARCHAR(6);
    _row_no VARCHAR(5);
    max_row_no INTEGER;
    _hsn_id INTEGER;
    _cgst DECIMAL(5,2) := 0;
    _sgst DECIMAL(5,2) := 0;
    _igst DECIMAL(5,2) := 0;
    _utgst DECIMAL(5,2) := 0;
BEGIN
    -- Get entry_no from header
    SELECT sh.entry_no INTO _entry_no FROM wms.sales_order_header sh WHERE sh.id = _header_id;

    -- Get next row_no for this entry
    SELECT COALESCE(MAX(CAST(sd.row_no AS INTEGER)), 0) INTO max_row_no
    FROM wms.sales_order_details sd
    WHERE sd.header_id = _header_id;

    _row_no := LPAD((max_row_no + 1)::TEXT, 5, '0');

    -- Look up HSN rates from material
    SELECT h.id, h.cgst, h.sgst, h.igst, h.utgst
    INTO _hsn_id, _cgst, _sgst, _igst, _utgst
    FROM wms.hsn h
    JOIN wms.material m ON m.hsn_id = h.id
    WHERE m.id = _item_id;

    INSERT INTO wms.sales_order_details(
        header_id, entry_no, row_no, item_id, euom, puom, quom,
        rate_per_pc, eqty, pqty, amount, dqty,
        hsn_id, cgst, sgst, igst, utgst,
        status, remarks, lub
    )
    VALUES (
        _header_id, _entry_no, _row_no, _item_id, _euom, _puom, _quom,
        _rate_per_pc, _eqty, _pqty, _amount, _dqty,
        _hsn_id, COALESCE(_cgst, 0), COALESCE(_sgst, 0), COALESCE(_igst, 0), COALESCE(_utgst, 0),
        _status, _remarks, _current_user_id
    )
    RETURNING id INTO _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to update sales_order_details
CREATE OR REPLACE FUNCTION wms.update_sales_order_details(
    _sales_order_details_id INTEGER,
    _header_id INTEGER,
    _item_id INTEGER,
    _euom INTEGER,
    _puom INTEGER,
    _quom INTEGER,
    _rate_per_pc DECIMAL(15,2),
    _eqty DECIMAL(15,3),
    _pqty DECIMAL(15,3),
    _amount DECIMAL(15,2),
    _dqty DECIMAL(15,3),
    _status VARCHAR(255),
    _remarks VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.sales_order_details
    SET header_id = _header_id,
        item_id = _item_id,
        euom = _euom,
        puom = _puom,
        quom = _quom,
        rate_per_pc = _rate_per_pc,
        eqty = _eqty,
        pqty = _pqty,
        amount = _amount,
        dqty = _dqty,
        status = _status,
        remarks = _remarks,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _sales_order_details_id;
    RETURN _sales_order_details_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete sales_order_details
CREATE OR REPLACE FUNCTION wms.delete_sales_order_details(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.sales_order_details
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

---------------------------** Picking List Header **---------------------------


--Function to insert in picking_list_header


--Function to delete  picking_list_header
CREATE OR REPLACE FUNCTION wms.delete_picking_list_header(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    -- Delete all picking_list_details associated with picking header
    PERFORM wms.delete_picking_details_by_header(_id, _current_user_id);
    
    --Delete picking header
    UPDATE wms.picking_list_header
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    RETURN _id;
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
    _entry_dt TIMESTAMP,
    _vendor_id INTEGER,
    _broker_id INTEGER,
    _delivery_at_id INTEGER,
    _trsp_id INTEGER,
    _delivery_dt TIMESTAMP,
    _status VARCHAR(255),
    _remarks VARCHAR(255),
    _current_user_id INTEGER
) RETURNS TABLE (id INTEGER, entry_no VARCHAR(10)) AS $$
DECLARE
    _new_id INTEGER;
    _new_entry_no VARCHAR(10);
    _max_entry_no INTEGER;
    _year_code VARCHAR(4);
BEGIN
    -- Compute fiscal year: starts April 1st
    _year_code := CASE
        WHEN EXTRACT(MONTH FROM CURRENT_DATE) >= 4
        THEN TO_CHAR(CURRENT_DATE, 'YYYY')
        ELSE TO_CHAR(CURRENT_DATE - INTERVAL '1 year', 'YYYY')
    END;

    -- Auto-generate entry_no with PO prefix
    SELECT COALESCE(
        MAX((REGEXP_REPLACE(ph.entry_no, '[^0-9]', '', 'g'))::INT),
        0
    ) INTO _max_entry_no
    FROM wms.purchase_order_header ph
    WHERE ph.entry_no ~ '^PO[0-9]+';

    _new_entry_no := 'PO' || LPAD((_max_entry_no + 1)::TEXT, 6, '0');

    INSERT INTO wms.purchase_order_header(
        entry_no, entry_dt, vendor_id, broker_id, delivery_at_id,
        trsp_id, year_code, delivery_dt, status, remarks, lub
    )
    VALUES (
        _new_entry_no, _entry_dt, _vendor_id, _broker_id, _delivery_at_id,
        _trsp_id, _year_code, _delivery_dt, _status, _remarks, _current_user_id
    )
    RETURNING purchase_order_header.id, purchase_order_header.entry_no INTO _new_id, _new_entry_no;
    
    RETURN QUERY SELECT _new_id, _new_entry_no;
END;
$$ LANGUAGE plpgsql;

--Function to update purchase_order_header
CREATE OR  REPLACE FUNCTION wms.update_purchase_order_header(
    purchase_list_header_id INT,
    entry_no VARCHAR(6),
    entry_dt TIMESTAMP,
    vendor_id INTEGER,
    broker_id INTEGER,
    delivery_at_id INTEGER,
    trsp_id INTEGER,
    delivery_dt TIMESTAMP,
    status VARCHAR(255),
    remarks VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    UPDATE  wms.purchase_order_header
    SET entry_no = entry_no,
        entry_dt = entry_dt,
        vendor_id = vendor_id,
        delivery_at_id = delivery_at_id,
        trsp_id = trsp_id,
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
    euom INTEGER,
    puom INTEGER,
    quom INTEGER,
    rate_per_pc DECIMAL(15,2),
    eqty DECIMAL(15,3),
    pqty DECIMAL(15,3),
    amount DECIMAL(15,2),
    iqty DECIMAL(15,3),
    status VARCHAR(255),
    remarks VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
DECLARE
    new_purchase_details_id INT;
    _entry_no VARCHAR(10);
    _row_no VARCHAR(5);
    _max_row INTEGER;
    _lock_key BIGINT;
    _hsn_id INTEGER;
    _cgst DECIMAL(5,2) := 0;
    _sgst DECIMAL(5,2) := 0;
    _igst DECIMAL(5,2) := 0;
    _utgst DECIMAL(5,2) := 0;
BEGIN
    -- Get entry_no from header
    SELECT entry_no INTO _entry_no
    FROM wms.purchase_order_header
    WHERE id = header_id;

    IF _entry_no IS NULL THEN
        RAISE EXCEPTION 'Purchase Order Header % not found', header_id;
    END IF;

    -- Acquire advisory lock to ensure unique row_no generation
    _lock_key := header_id::BIGINT;
    PERFORM pg_advisory_xact_lock(_lock_key);

    -- Generate next row_no for this header
    SELECT COALESCE(MAX(CAST(row_no AS INTEGER)), 0) INTO _max_row
    FROM wms.purchase_order_details
    WHERE wms.purchase_order_details.header_id = insert_purchase_order_details.header_id;

    _row_no := LPAD((_max_row + 1)::TEXT, 5, '0');

    -- Look up HSN rates from material
    SELECT h.id, h.cgst, h.sgst, h.igst, h.utgst
    INTO _hsn_id, _cgst, _sgst, _igst, _utgst
    FROM wms.hsn h
    JOIN wms.material m ON m.hsn_id = h.id
    WHERE m.id = item_id;

    INSERT INTO wms.purchase_order_details(
        header_id, entry_no, row_no,
        item_id, euom, puom, quom,
        rate_per_pc, eqty, pqty, amount, iqty,
        hsn_id, cgst, sgst, igst, utgst,
        status, remarks, lub
    )
    VALUES (
        header_id, _entry_no, _row_no,
        item_id, euom, puom, quom,
        rate_per_pc, eqty, pqty, amount, iqty,
        _hsn_id, COALESCE(_cgst, 0), COALESCE(_sgst, 0), COALESCE(_igst, 0), COALESCE(_utgst, 0),
        status, remarks, current_user_id
    )
    RETURNING id INTO new_purchase_details_id;

    RETURN new_purchase_details_id;
END;
$$ LANGUAGE plpgsql;

--Function to update purchase_order_details
CREATE OR REPLACE FUNCTION wms.update_purchase_order_details(
    purchase_order_details_id INTEGER,
    header_id INTEGER,
    item_id INTEGER,
    euom INTEGER,
    puom INTEGER,
    quom INTEGER,
    rate_per_pc DECIMAL(15,2),
    eqty DECIMAL(15,3),
    pqty DECIMAL(15,3),
    amount DECIMAL(15,2),
    iqty DECIMAL(15,3),
    status VARCHAR(255),
    remarks VARCHAR(255),
    current_user_id INTEGER
)RETURNS INT AS $$
BEGIN
    UPDATE wms.purchase_order_details
    SET header_id = header_id,
        item_id = item_id,
        euom = euom,
        puom = puom,
        quom = quom,
        rate_per_pc = rate_per_pc,
        eqty = eqty,
        pqty = pqty,
        amount = amount,
        iqty = iqty,
        status = status,
        remarks = remarks,
        lub = current_user_id,
        lua = NOW()
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

---------------------------** Inward Header **---------------------------

-- Function to insert in inward_header
CREATE OR REPLACE FUNCTION wms.insert_inward_header(
    p_entry_dt DATE,
    p_vendor_id INTEGER,
    p_po_ids TEXT,
    p_invoice_no VARCHAR(100),
    p_invoice_dt DATE,
    p_remarks VARCHAR(255),
    p_current_user_id INTEGER
) RETURNS TABLE (id INTEGER, entry_no VARCHAR) AS $$
DECLARE
    v_new_id INT;
    v_entry_no VARCHAR(50);
    v_max INT;
    v_new_no INT;
    -- Fixed advisory lock key to serialize generation (change if needed)
    CONSTANT_lock_key BIGINT := 987654321;
BEGIN
    -- Acquire transaction-scoped advisory lock to ensure atomic generation
    PERFORM pg_advisory_xact_lock(CONSTANT_lock_key);

    -- Compute numeric part robustly by stripping non-digits and taking max
    SELECT COALESCE(
        MAX((REGEXP_REPLACE(h.entry_no, '[^0-9]', '', 'g'))::INT),
        0
    )
    INTO v_max
    FROM wms.inward_header h
    WHERE h.entry_no ~ '^INW[0-9]+';

    v_new_no := v_max + 1;
    v_entry_no := 'INW' || LPAD(v_new_no::TEXT, 6, '0');

    INSERT INTO wms.inward_header(entry_no, entry_dt, vendor_id, po_ids, invoice_no, invoice_dt, remarks, lub, status)
    VALUES (v_entry_no, p_entry_dt, p_vendor_id, p_po_ids, p_invoice_no, p_invoice_dt, p_remarks, p_current_user_id, 'Draft')
    RETURNING wms.inward_header.id, wms.inward_header.entry_no INTO v_new_id, v_entry_no;

    RETURN QUERY SELECT v_new_id, v_entry_no;
END;
$$ LANGUAGE plpgsql;

-- Function to update inward_header
CREATE OR REPLACE FUNCTION wms.update_inward_header(
    p_id INTEGER,
    p_entry_dt DATE,
    p_vendor_id INTEGER,
    p_po_ids TEXT,
    p_invoice_no VARCHAR(100),
    p_invoice_dt DATE,
    p_status VARCHAR(50),
    p_remarks VARCHAR(255),
    p_current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    -- Update header fields. entry_no is immutable and is NOT changed here.
    UPDATE wms.inward_header
    SET entry_dt = p_entry_dt,
        vendor_id = p_vendor_id,
        po_ids = p_po_ids,
        invoice_no = p_invoice_no,
        invoice_dt = p_invoice_dt,
        status = p_status,
        remarks = p_remarks,
        lub = p_current_user_id,
        lua = NOW()
    WHERE id = p_id;

    RETURN p_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete inward_header
CREATE OR REPLACE FUNCTION wms.delete_inward_header(
    p_id INTEGER,
    p_current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    -- Ensure the inward exists and is active
    IF NOT EXISTS (SELECT 1 FROM wms.inward_header WHERE id = p_id AND is_active = true) THEN
        RAISE EXCEPTION 'Inward % not found or already deleted', p_id;
    END IF;

    -- Do not allow deletion of processed inwards
    IF EXISTS (SELECT 1 FROM wms.inward_header WHERE id = p_id AND status = 'Processed') THEN
        RAISE EXCEPTION 'Cannot delete Inward %: already Processed', p_id;
    END IF;

    -- Soft delete header
    UPDATE wms.inward_header
    SET is_active = false,
        lub = p_current_user_id,
        lua = NOW()
    WHERE id = p_id;

    -- Soft delete associated details
    UPDATE wms.inward_details
    SET is_active = false,
        lub = p_current_user_id,
        lua = NOW()
    WHERE header_id = p_id;

    RETURN p_id;
END;
$$ LANGUAGE plpgsql;

---------------------------** Inward Details **---------------------------

-- Function to insert in inward_details
CREATE OR REPLACE FUNCTION wms.insert_inward_details(
    p_header_id INTEGER,
    p_ean_id INTEGER,
    p_po_detail_id INTEGER,
    p_quom INTEGER,
    p_euom INTEGER,
    p_puom INTEGER,
    p_eqty DECIMAL(15,3),
    p_pqty DECIMAL(15,3),
    p_pur_rate DECIMAL(15,2),
    p_amount DECIMAL(15,2),
    p_expiry_dt DATE,
    p_batch_no VARCHAR(100),
    p_remarks VARCHAR(255),
    p_current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _new_id INTEGER;
    _entry_no VARCHAR(50);
    _row_no VARCHAR(5);
    _row_no_int INTEGER;
    _lock_key BIGINT;
    _hsn_id INTEGER;
    _cgst DECIMAL(5,2) := 0;
    _sgst DECIMAL(5,2) := 0;
    _igst DECIMAL(5,2) := 0;
    _utgst DECIMAL(5,2) := 0;
BEGIN
    -- Ensure header exists and is active
    IF NOT EXISTS (SELECT 1 FROM wms.inward_header WHERE id = p_header_id AND is_active = true) THEN
        RAISE EXCEPTION 'Inward header % not found or inactive', p_header_id;
    END IF;

    -- Do not allow inserting details into a processed inward
    IF EXISTS (SELECT 1 FROM wms.inward_header WHERE id = p_header_id AND status = 'Processed') THEN
        RAISE EXCEPTION 'Cannot add details to Processed Inward %', p_header_id;
    END IF;

    -- Get entry_no from header
    SELECT entry_no INTO _entry_no FROM wms.inward_header WHERE id = p_header_id;

    -- Acquire an advisory transaction lock scoped to this header to avoid duplicate row_no under concurrency
    _lock_key := p_header_id::BIGINT;
    PERFORM pg_advisory_xact_lock(_lock_key);

    -- Compute next row_no safely within the lock
    SELECT COALESCE(MAX(CAST(row_no AS INTEGER)), 0) INTO _row_no_int
    FROM wms.inward_details
    WHERE header_id = p_header_id;

    _row_no := LPAD((_row_no_int + 1)::TEXT, 5, '0');

    -- Look up HSN rates via ean -> material_ean -> material -> hsn
    SELECT h.id, h.cgst, h.sgst, h.igst, h.utgst
    INTO _hsn_id, _cgst, _sgst, _igst, _utgst
    FROM wms.hsn h
    JOIN wms.material m ON m.hsn_id = h.id
    JOIN wms.material_ean me ON me.material_id = m.id
    WHERE me.id = p_ean_id;

    INSERT INTO wms.inward_details (
        header_id, entry_no, row_no, ean_id, po_detail_id,
        quom, euom, puom, eqty, pqty, pur_rate, amount,
        hsn_id, cgst, sgst, igst, utgst,
        expiry_dt, batch_no, remarks, lub
    )
    VALUES (
        p_header_id, _entry_no, _row_no, p_ean_id, p_po_detail_id,
        p_quom, p_euom, p_puom, p_eqty, p_pqty, p_pur_rate, p_amount,
        _hsn_id, COALESCE(_cgst, 0), COALESCE(_sgst, 0), COALESCE(_igst, 0), COALESCE(_utgst, 0),
        p_expiry_dt, p_batch_no, p_remarks, p_current_user_id
    )
    RETURNING id INTO _new_id;

    RETURN _new_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update inward_details
CREATE OR REPLACE FUNCTION wms.update_inward_details(
    p_id INTEGER,
    p_header_id INTEGER,
    p_ean_id INTEGER,
    p_po_detail_id INTEGER,
    p_quom INTEGER,
    p_euom INTEGER,
    p_puom INTEGER,
    p_eqty DECIMAL(15,3),
    p_pqty DECIMAL(15,3),
    p_pur_rate DECIMAL(15,2),
    p_amount DECIMAL(15,2),
    p_expiry_dt DATE,
    p_batch_no VARCHAR(100),
    p_remarks VARCHAR(255),
    p_current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    -- Validate header exists and is active
    IF NOT EXISTS (SELECT 1 FROM wms.inward_header WHERE id = p_header_id AND is_active = true) THEN
        RAISE EXCEPTION 'Inward header % not found or inactive', p_header_id;
    END IF;

    -- Do not allow updates to details of a processed inward
    IF EXISTS (SELECT 1 FROM wms.inward_header WHERE id = p_header_id AND status = 'Processed') THEN
        RAISE EXCEPTION 'Cannot update details for Processed Inward %', p_header_id;
    END IF;

    UPDATE wms.inward_details
    SET ean_id = p_ean_id,
        po_detail_id = p_po_detail_id,
        quom = p_quom,
        euom = p_euom,
        puom = p_puom,
        eqty = p_eqty,
        pqty = p_pqty,
        pur_rate = p_pur_rate,
        amount = p_amount,
        expiry_dt = p_expiry_dt,
        batch_no = p_batch_no,
        remarks = p_remarks,
        lub = p_current_user_id,
        lua = NOW()
    WHERE id = p_id;

    RETURN p_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete inward_details (soft delete)
CREATE OR REPLACE FUNCTION wms.delete_inward_details(
    p_id INTEGER,
    p_current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _header_id INTEGER;
BEGIN
    -- Ensure detail exists and is active
    IF NOT EXISTS (SELECT 1 FROM wms.inward_details WHERE id = p_id AND is_active = true) THEN
        RAISE EXCEPTION 'Inward detail % not found or already deleted', p_id;
    END IF;

    -- Get parent header and ensure it's not processed
    SELECT header_id INTO _header_id FROM wms.inward_details WHERE id = p_id;
    IF EXISTS (SELECT 1 FROM wms.inward_header WHERE id = _header_id AND status = 'Processed') THEN
        RAISE EXCEPTION 'Cannot delete detail %: parent Inward % is Processed', p_id, _header_id;
    END IF;

    -- Soft delete detail
    UPDATE wms.inward_details
    SET is_active = false, lub = p_current_user_id, lua = NOW()
    WHERE id = p_id;

    RETURN p_id;
END;
$$ LANGUAGE plpgsql;

-- Function to process inward (stock update & PO fulfillment)
CREATE OR REPLACE FUNCTION wms.process_inward(
    p_header_id INTEGER,
    p_current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _detail RECORD;
    _po_header_id INTEGER;
    _po_ids_to_check INTEGER[] := '{}';
    _all_completed BOOLEAN;
    _lock_key BIGINT;
BEGIN
    -- Acquire advisory lock per header to prevent concurrent processing
    _lock_key := p_header_id::BIGINT;
    PERFORM pg_advisory_xact_lock(_lock_key);

    -- Validate header exists and is Draft
    IF NOT EXISTS (SELECT 1 FROM wms.inward_header WHERE id = p_header_id AND status = 'Draft' AND is_active = true) THEN
        RAISE EXCEPTION 'Inward % not found or not in Draft status', p_header_id;
    END IF;

    -- Mark header as Processed (idempotency guard)
    UPDATE wms.inward_header
    SET status = 'Processed', lub = p_current_user_id, lua = NOW()
    WHERE id = p_header_id;

    -- Loop through active details and upsert stock
    FOR _detail IN SELECT * FROM wms.inward_details WHERE header_id = p_header_id AND is_active = true LOOP

        INSERT INTO wms.stock (ean_id, rack_id, expiry_dt, batch_no, qty, uom_id, rate, lub)
        VALUES (
            _detail.ean_id,
            1,
            _detail.expiry_dt,
            _detail.batch_no,
            COALESCE(_detail.eqty,0),
            _detail.euom,
            (SELECT rate_per_pc FROM wms.purchase_order_details WHERE id = _detail.po_detail_id),
            p_current_user_id
        )
        ON CONFLICT (batch_no, rack_id) DO UPDATE
        SET qty = wms.stock.qty + EXCLUDED.qty,
            uom_id = EXCLUDED.uom_id,
            rate = COALESCE(EXCLUDED.rate, wms.stock.rate),
            lub = EXCLUDED.lub,
            lua = NOW();

        -- Update PO detail iqty if linked and collect PO header ids for completion check
        IF _detail.po_detail_id IS NOT NULL THEN
            UPDATE wms.purchase_order_details
            SET iqty = COALESCE(iqty,0) + COALESCE(_detail.eqty,0),
                lub = p_current_user_id,
                lua = NOW()
            WHERE id = _detail.po_detail_id
            RETURNING header_id INTO _po_header_id;

            IF _po_header_id IS NOT NULL AND NOT (_po_header_id = ANY(_po_ids_to_check)) THEN
                _po_ids_to_check := array_append(_po_ids_to_check, _po_header_id);
            END IF;
        END IF;

    END LOOP;

    -- Check and update PO header status for collected PO headers
    IF array_length(_po_ids_to_check,1) > 0 THEN
        FOREACH _po_header_id IN ARRAY _po_ids_to_check LOOP
            SELECT NOT EXISTS (
                SELECT 1 FROM wms.purchase_order_details pd
                WHERE pd.header_id = _po_header_id
                AND pd.is_active = true
                AND COALESCE(pd.iqty,0) < COALESCE(pd.eqty,0)
            ) INTO _all_completed;

            IF _all_completed THEN
                UPDATE wms.purchase_order_header
                SET status = 'Completed', lub = p_current_user_id, lua = NOW()
                WHERE id = _po_header_id;
            END IF;
        END LOOP;
    END IF;

    RETURN p_header_id;
END;
$$ LANGUAGE plpgsql;

---------------------------** Address **---------------------------

-- Function to insert in address
CREATE OR REPLACE FUNCTION wms.insert_address(
    _adr1 VARCHAR(255),
    _adr2 VARCHAR(255),
    _adr3 VARCHAR(255),
    _city_id INTEGER,
    _district_id INTEGER,
    _state_id INTEGER,
    _country_id INTEGER,
    _current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_address_id INT;
BEGIN
    INSERT INTO wms.address (adr1, adr2, adr3, city_id, district_id, state_id, country_id, lub)
    VALUES (_adr1, _adr2, _adr3, _city_id, _district_id, _state_id, _country_id, _current_user_id)
    RETURNING id INTO new_address_id;
    RETURN new_address_id;
END;
$$ LANGUAGE plpgsql;

--Function to update address
CREATE OR REPLACE FUNCTION wms.update_address(
    _address_id INT,
    _adr1 VARCHAR(255),
    _adr2 VARCHAR(255),
    _adr3 VARCHAR(255),
    _city_id INTEGER,
    _district_id INTEGER,
    _state_id INTEGER,
    _country_id INTEGER,
    _current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.address
    SET adr1 = _adr1,
        adr2 = _adr2,
        adr3 = _adr3,
        city_id = _city_id,
        district_id = _district_id,
        state_id = _state_id,
        country_id = _country_id,
        lub = _current_user_id
    WHERE id = _address_id;
    RETURN _address_id;
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
    _city_id INT,
    _city_name VARCHAR(100),
    _city_code VARCHAR(3),
    _descr VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.city
    SET name = _city_name,
        code = _city_code,
        descr = _descr,
        lub = _current_user_id
    WHERE id = _city_id;
    RETURN _city_id;
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
    _district_id INT,
    _district_name VARCHAR(100),
    _district_code VARCHAR(3),
    _descr VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.district
    SET name = _district_name,
        code = _district_code,
        descr = _descr,
        lub = _current_user_id
    WHERE id = _district_id;
    RETURN _district_id;
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
    _city_id INT,
    _district_id INT,
    _state_id INT,
    _descr VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INT AS $$
DECLARE new_city_district_id INT;
BEGIN
    INSERT INTO wms.city_district (city_id, district_id, state_id, descr, lub)
    VALUES (_city_id, _district_id, _state_id, _descr, _current_user_id)
    RETURNING id INTO new_city_district_id;
    RETURN new_city_district_id;
END;
$$ LANGUAGE plpgsql;


-- Function to update city_district
CREATE OR REPLACE FUNCTION wms.update_city_district(
    _city_district_id INT,
    _city_id INT,
    _district_id INT,
    _state_id INT,
    _descr VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.city_district
    SET city_id = _city_id,
        district_id = _district_id,
        state_id = _state_id,
        descr = _descr,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _city_district_id;
    RETURN _city_district_id;
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
DECLARE
    city_ids_to_delete INTEGER[];
    district_ids_to_delete INTEGER[];
BEGIN
    -- Get all city IDs that are mapped to this state
    SELECT ARRAY_AGG(DISTINCT city_id) INTO city_ids_to_delete
    FROM wms.city_district
    WHERE state_id = state_id_to_delete AND is_active = true;
    
    -- Get all district IDs that are mapped to this state
    SELECT ARRAY_AGG(DISTINCT district_id) INTO district_ids_to_delete
    FROM wms.city_district
    WHERE state_id = state_id_to_delete AND is_active = true;
    
    -- Delete city_district mappings
    UPDATE wms.city_district
    SET is_active = false,
        lub = deleted_by_user_id
    WHERE state_id = state_id_to_delete;
    
    -- Delete cities that were in the mappings
    IF city_ids_to_delete IS NOT NULL THEN
        UPDATE wms.city
        SET is_active = false, lub = deleted_by_user_id
        WHERE id = ANY(city_ids_to_delete);
    END IF;
    
    -- Delete districts that were in the mappings
    IF district_ids_to_delete IS NOT NULL THEN
        UPDATE wms.district
        SET is_active = false, lub = deleted_by_user_id
        WHERE id = ANY(district_ids_to_delete);
    END IF;
END;
$$ LANGUAGE plpgsql;

---------------------------** Party Category Master **---------------------------

-- Function to insert party category
CREATE OR REPLACE FUNCTION wms.insert_party_category(
    _name VARCHAR(100),
    _discount_percentage NUMERIC(5,2),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _id INTEGER;
BEGIN
    INSERT INTO wms.party_category (name, discount_percentage, lub)
    VALUES (_name, _discount_percentage, _current_user_id)
    RETURNING id INTO _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to update party category
CREATE OR REPLACE FUNCTION wms.update_party_category(
    _id INTEGER,
    _name VARCHAR(100),
    _discount_percentage NUMERIC(5,2),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.party_category
    SET 
        name = _name,
        discount_percentage = _discount_percentage,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete party category
CREATE OR REPLACE FUNCTION wms.delete_party_category(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.party_category
    SET is_active = false, lub = _current_user_id
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

---------------------------** Party Master **---------------------------

-- Function to insert party
CREATE OR REPLACE FUNCTION wms.insert_party(
    _category_id INTEGER,
    _party_type VARCHAR(50),
    _name VARCHAR(100),
    _add1 VARCHAR(100),
    _add2 VARCHAR(100),
    _add3 VARCHAR(100),
    _city_id INTEGER,
    _district_id INTEGER,
    _state_id INTEGER,
    _country_id INTEGER,
    _pincode VARCHAR(10),
    _salesman VARCHAR(100),
    _pan_no VARCHAR(20),
    _cr_limit DECIMAL(15,2),
    _cr_days INTEGER,
    _gstno VARCHAR(20),
    _aadhar_no VARCHAR(20),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _id INTEGER;
BEGIN
    INSERT INTO wms.party (
        category_id, party_type, name, add1, add2, add3,
        city_id, district_id, state_id, country_id, pincode,
        salesman, pan_no, cr_limit, cr_days, gstno, aadhar_no, lub
    ) VALUES (
        _category_id, _party_type, _name, _add1, _add2, _add3,
        _city_id, _district_id, _state_id, _country_id, _pincode,
        _salesman, _pan_no, _cr_limit, _cr_days, _gstno, _aadhar_no, _current_user_id
    ) RETURNING id INTO _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to update party
CREATE OR REPLACE FUNCTION wms.update_party(
    _id INTEGER,
    _category_id INTEGER,
    _party_type VARCHAR(50),
    _name VARCHAR(100),
    _add1 VARCHAR(100),
    _add2 VARCHAR(100),
    _add3 VARCHAR(100),
    _city_id INTEGER,
    _district_id INTEGER,
    _state_id INTEGER,
    _country_id INTEGER,
    _pincode VARCHAR(10),
    _salesman VARCHAR(100),
    _pan_no VARCHAR(20),
    _cr_limit DECIMAL(15,2),
    _cr_days INTEGER,
    _gstno VARCHAR(20),
    _aadhar_no VARCHAR(20),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.party
    SET
        category_id = _category_id,
        party_type = _party_type,
        name = _name,
        add1 = _add1,
        add2 = _add2,
        add3 = _add3,
        city_id = _city_id,
        district_id = _district_id,
        state_id = _state_id,
        country_id = _country_id,
        pincode = _pincode,
        salesman = _salesman,
        pan_no = _pan_no,
        cr_limit = _cr_limit,
        cr_days = _cr_days,
        gstno = _gstno,
        aadhar_no = _aadhar_no,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

---------------------------** Party Contact Details **---------------------------

CREATE OR REPLACE FUNCTION wms.insert_party_contact(
    _party_id INTEGER,
    _name VARCHAR(100),
    _telephone VARCHAR(20),
    _email VARCHAR(100),
    _position VARCHAR(100),
    _descr VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _id INTEGER;
BEGIN
    INSERT INTO wms.party_contact_details (
        party_id, name, telephone, email, position, descr, lub
    ) VALUES (
        _party_id, _name, _telephone, _email, _position, _descr, _current_user_id
    ) RETURNING id INTO _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION wms.update_party_contact(
    _id INTEGER,
    _name VARCHAR(100),
    _telephone VARCHAR(20),
    _email VARCHAR(100),
    _position VARCHAR(100),
    _descr VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.party_contact_details
    SET name = _name,
        telephone = _telephone,
        email = _email,
        position = _position,
        descr = _descr,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION wms.delete_party_contact(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.party_contact_details
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

--Function to delete party
CREATE OR REPLACE FUNCTION wms.delete_party(
    party_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS INT  AS $$
BEGIN
    -- Delete party contacts
    UPDATE wms.party_contact_details
    SET is_active = false, lub = deleted_by_user_id, lua = NOW()
    WHERE party_id = party_id_to_delete AND is_active = true;
    -- Delete party
    UPDATE wms.party
    SET is_active = false, lub = deleted_by_user_id
    WHERE id = party_id_to_delete;
    RETURN party_id_to_delete;
END;
$$ LANGUAGE plpgsql;


---------------------------** Transport Master **---------------------------

-- Function to insert transport
CREATE OR REPLACE FUNCTION wms.insert_transport(
    _name VARCHAR(255),
    _descr VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _id INTEGER;
BEGIN
    INSERT INTO wms.transport (name, descr, lub)
    VALUES (_name, _descr, _current_user_id)
    RETURNING id INTO _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to update transport
CREATE OR REPLACE FUNCTION wms.update_transport(
    _id INTEGER,
    _name VARCHAR(255),
    _descr VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.transport
    SET name = _name,
        descr = _descr,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete transport (soft delete)
CREATE OR REPLACE FUNCTION wms.delete_transport(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.transport
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    RETURN _id;
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
    _uom_id INT,
    _uom_name VARCHAR(255),
    _descr VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.uom
    SET name = _uom_name,
        descr = _descr,
        lub = _current_user_id
    WHERE id = _uom_id;
    RETURN _uom_id;
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


---------------------------** Vendor Category Master **---------------------------

-- Function to insert vendor category
CREATE OR REPLACE FUNCTION wms.insert_vendor_category(
    _name VARCHAR(100),
    _discount_percentage NUMERIC(5,2),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _id INTEGER;
BEGIN
    INSERT INTO wms.vendor_category (name, discount_percentage, lub)
    VALUES (_name, _discount_percentage, _current_user_id)
    RETURNING id INTO _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to update vendor category
CREATE OR REPLACE FUNCTION wms.update_vendor_category(
    _id INTEGER,
    _name VARCHAR(100),
    _discount_percentage NUMERIC(5,2),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.vendor_category
    SET 
        name = _name,
        discount_percentage = _discount_percentage,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete vendor category
CREATE OR REPLACE FUNCTION wms.delete_vendor_category(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.vendor_category
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

---------------------------** Vendor Master **---------------------------

-- Function to insert vendor
CREATE OR REPLACE FUNCTION wms.insert_vendor(
    _category_id INTEGER,
    _vendor_type VARCHAR(50),
    _name VARCHAR(100),
    _add1 VARCHAR(100),
    _add2 VARCHAR(100),
    _add3 VARCHAR(100),
    _city_id INTEGER,
    _district_id INTEGER,
    _state_id INTEGER,
    _country_id INTEGER,
    _pincode VARCHAR(10),
    _salesman VARCHAR(100),
    _pan_no VARCHAR(20),
    _cr_limit DECIMAL(15,2),
    _cr_days INTEGER,
    _gstno VARCHAR(20),
    _aadhar_no VARCHAR(20),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _id INTEGER;
BEGIN
    INSERT INTO wms.vendor (
        category_id, vendor_type, name, add1, add2, add3,
        city_id, district_id, state_id, country_id, pincode,
        salesman, pan_no, cr_limit, cr_days, gstno, aadhar_no, lub
    ) VALUES (
        _category_id, _vendor_type, _name, _add1, _add2, _add3,
        _city_id, _district_id, _state_id, _country_id, _pincode,
        _salesman, _pan_no, _cr_limit, _cr_days, _gstno, _aadhar_no, _current_user_id
    ) RETURNING id INTO _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to update vendor
CREATE OR REPLACE FUNCTION wms.update_vendor(
    _id INTEGER,
    _category_id INTEGER,
    _vendor_type VARCHAR(50),
    _name VARCHAR(100),
    _add1 VARCHAR(100),
    _add2 VARCHAR(100),
    _add3 VARCHAR(100),
    _city_id INTEGER,
    _district_id INTEGER,
    _state_id INTEGER,
    _country_id INTEGER,
    _pincode VARCHAR(10),
    _salesman VARCHAR(100),
    _pan_no VARCHAR(20),
    _cr_limit DECIMAL(15,2),
    _cr_days INTEGER,
    _gstno VARCHAR(20),
    _aadhar_no VARCHAR(20),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.vendor
    SET
        category_id = _category_id,
        vendor_type = _vendor_type,
        name = _name,
        add1 = _add1,
        add2 = _add2,
        add3 = _add3,
        city_id = _city_id,
        district_id = _district_id,
        state_id = _state_id,
        country_id = _country_id,
        pincode = _pincode,
        salesman = _salesman,
        pan_no = _pan_no,
        cr_limit = _cr_limit,
        cr_days = _cr_days,
        gstno = _gstno,
        aadhar_no = _aadhar_no,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

---------------------------** Vendor Contact Details **---------------------------

CREATE OR REPLACE FUNCTION wms.insert_vendor_contact(
    _vendor_id INTEGER,
    _name VARCHAR(100),
    _telephone VARCHAR(20),
    _email VARCHAR(100),
    _position VARCHAR(100),
    _descr VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _id INTEGER;
BEGIN
    INSERT INTO wms.vendor_contact_details (
        vendor_id, name, telephone, email, position, descr, lub
    ) VALUES (
        _vendor_id, _name, _telephone, _email, _position, _descr, _current_user_id
    ) RETURNING id INTO _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION wms.update_vendor_contact(
    _id INTEGER,
    _name VARCHAR(100),
    _telephone VARCHAR(20),
    _email VARCHAR(100),
    _position VARCHAR(100),
    _descr VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.vendor_contact_details
    SET name = _name,
        telephone = _telephone,
        email = _email,
        position = _position,
        descr = _descr,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION wms.delete_vendor_contact(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.vendor_contact_details
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete vendor
CREATE OR REPLACE FUNCTION wms.delete_vendor(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    -- Delete vendor contacts
    UPDATE wms.vendor_contact_details
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE vendor_id = _id AND is_active = true;
    -- Delete vendor
    UPDATE wms.vendor
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;


---------------------------** Broker Master **---------------------------

-- Function to insert broker
CREATE OR REPLACE FUNCTION wms.insert_broker(
    broker_type VARCHAR(50),
    broker_name VARCHAR(50),
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
    country_id INTEGER,
    aadhar_no VARCHAR(50),
    sales_head VARCHAR(50),
    director VARCHAR(50),
    manager VARCHAR(50),
    city_district_id INTEGER,
    state_id INTEGER,
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
        country_id, 
        aadhar_no, 
        sales_head, 
        director, 
        manager, 
        city_district_id,
        state_id, lub
    )
    VALUES (
        broker_type, 
        broker_name, 
        add1, 
        add2, 
        add3, 
        city, 
        pincode, 
        person_name,
        telephone, 
        p_email, 
        udate, 
        salesman, 
        pan_no, 
        cr_limit, 
        cr_days, 
        gstno,
        country_id, 
        aadhar_no, 
        sales_head, 
        director, 
        manager, 
        city_district_id,
        state_id, 
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
    broker_name VARCHAR(50),
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
    country_id INTEGER,
    aadhar_no VARCHAR(50),
    sales_head VARCHAR(50),
    director VARCHAR(50),
    manager VARCHAR(50),
    city_district_id INTEGER,
    state_id INTEGER,
    current_user_id INTEGER
) RETURNS INT AS $$
BEGIN
    UPDATE wms.broker
    SET broker_type = broker_type,
        name = broker_name,
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


---------------------------** WMS CRUD FUNCTIONS **---------------------------
-- This file contains all CRUD functions for the new WMS tables
-- To be appended to the existing query_functions.sql file

---------------------------** Rack Master **---------------------------

-- Function to insert rack
CREATE OR REPLACE FUNCTION wms.insert_rack(
    _code VARCHAR(50),
    _name VARCHAR(255),
    _descr VARCHAR(255),
    _capacity DECIMAL(15,3),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _id INTEGER;
BEGIN
    INSERT INTO wms.rack (code, name, descr, capacity, lub)
    VALUES (_code, _name, _descr, _capacity, _current_user_id)
    RETURNING id INTO _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to update rack
CREATE OR REPLACE FUNCTION wms.update_rack(
    _id INTEGER,
    _code VARCHAR(50),
    _name VARCHAR(255),
    _descr VARCHAR(255),
    _capacity DECIMAL(15,3),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.rack
    SET code = _code,
        name = _name,
        descr = _descr,
        capacity = _capacity,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete rack (soft delete)
CREATE OR REPLACE FUNCTION wms.delete_rack(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.rack
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;


---------------------------** Party Material (Party-Specific Pricing) **---------------------------

-- Function to insert party_material
CREATE OR REPLACE FUNCTION wms.insert_party_material(
    _material_id INTEGER,
    _party_id INTEGER,
    _selling_rate DECIMAL(15,2),
    _date DATE,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _id INTEGER;
BEGIN
    INSERT INTO wms.party_material (material_id, party_id, selling_rate, date, lub)
    VALUES (_material_id, _party_id, _selling_rate, _date, _current_user_id)
    RETURNING id INTO _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to update party_material
CREATE OR REPLACE FUNCTION wms.update_party_material(
    _id INTEGER,
    _material_id INTEGER,
    _party_id INTEGER,
    _selling_rate DECIMAL(15,2),
    _date DATE,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.party_material
    SET material_id = _material_id,
        party_id = _party_id,
        selling_rate = _selling_rate,
        date = _date,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete party_material (soft delete)
CREATE OR REPLACE FUNCTION wms.delete_party_material(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.party_material
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to get party-specific price for a material
CREATE OR REPLACE FUNCTION wms.get_party_material_price(
    _material_id INTEGER,
    _party_id INTEGER
) RETURNS DECIMAL(15,2) AS $$
DECLARE
    _selling_rate DECIMAL(15,2);
BEGIN
    -- Get the most recent price for this party-material combination
    SELECT selling_rate INTO _selling_rate
    FROM wms.party_material
    WHERE material_id = _material_id 
      AND party_id = _party_id 
      AND is_active = true
    ORDER BY date DESC
    LIMIT 1;
    
    -- If no party-specific price found, return NULL
    RETURN _selling_rate;
END;
$$ LANGUAGE plpgsql;


---------------------------** Dispatch Header **---------------------------

-- Function to insert dispatch_header
CREATE OR REPLACE FUNCTION wms.insert_dispatch_header(
    entry_dt DATE,
    party_id INTEGER,
    addr_id INTEGER,
    pl_ids TEXT,
    vehicle_no VARCHAR(50),
    driver_name VARCHAR(255),
    remarks VARCHAR(255),
    current_user_id INTEGER
) RETURNS TABLE (id INTEGER, entry_no VARCHAR) AS $$
DECLARE 
    new_dispatch_header_id INT;
    new_entry_no VARCHAR(50);
    max_entry_no INT;
BEGIN
    -- Auto-generate entry_no
    SELECT COALESCE(MAX(CAST(h.entry_no AS INTEGER)), 0) INTO max_entry_no 
    FROM wms.dispatch_header h;
    
    new_entry_no := LPAD((max_entry_no + 1)::TEXT, 6, '0');

    INSERT INTO wms.dispatch_header(
        entry_no, entry_dt, party_id, addr_id, pl_ids, vehicle_no, driver_name, remarks, lub
    )
    VALUES (
        new_entry_no, entry_dt, party_id, addr_id, pl_ids, vehicle_no, driver_name, remarks, current_user_id
    )
    RETURNING wms.dispatch_header.id INTO new_dispatch_header_id;
    
    RETURN QUERY SELECT new_dispatch_header_id, new_entry_no;
END;
$$ LANGUAGE plpgsql;

-- Function to update dispatch_header
CREATE OR REPLACE FUNCTION wms.update_dispatch_header(
    _id INTEGER,
    _entry_dt DATE,
    _party_id INTEGER,
    _addr_id INTEGER,
    _pl_ids TEXT,
    _vehicle_no VARCHAR(50),
    _driver_name VARCHAR(255),
    _remarks VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.dispatch_header
    SET entry_dt = _entry_dt,
        party_id = _party_id,
        addr_id = _addr_id,
        pl_ids = _pl_ids,
        vehicle_no = _vehicle_no,
        driver_name = _driver_name,
        remarks = _remarks,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete dispatch_header (soft delete)
CREATE OR REPLACE FUNCTION wms.delete_dispatch_header(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    -- Soft delete header
    UPDATE wms.dispatch_header
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    
    -- Also soft delete all details
    UPDATE wms.dispatch_details
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE header_id = _id;
    
    RETURN _id;
END;
$$ LANGUAGE plpgsql;


---------------------------** Dispatch Details **---------------------------

-- Function to insert dispatch_details
CREATE OR REPLACE FUNCTION wms.insert_dispatch_details(
    _header_id INTEGER,
    _entry_no VARCHAR(50),
    _row_no INTEGER,
    _material_id INTEGER,
    _picking_detail_id INTEGER,
    _rack_id INTEGER,
    _qty DECIMAL(15,3),
    _uom_id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE _id INTEGER;
BEGIN
    INSERT INTO wms.dispatch_details(
        header_id, entry_no, row_no, material_id, picking_detail_id,
        rack_id, qty, uom_id, lub
    )
    VALUES (
        _header_id, _entry_no, _row_no, _material_id, _picking_detail_id,
        _rack_id, _qty, _uom_id, _current_user_id
    )
    RETURNING id INTO _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to update dispatch_details
CREATE OR REPLACE FUNCTION wms.update_dispatch_details(
    _id INTEGER,
    _material_id INTEGER,
    _picking_detail_id INTEGER,
    _rack_id INTEGER,
    _qty DECIMAL(15,3),
    _uom_id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.dispatch_details
    SET material_id = _material_id,
        picking_detail_id = _picking_detail_id,
        rack_id = _rack_id,
        qty = _qty,
        uom_id = _uom_id,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete dispatch_details (soft delete)
CREATE OR REPLACE FUNCTION wms.delete_dispatch_details(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.dispatch_details
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;


---------------------------** Stock Management **---------------------------

-- Function to update or insert stock (for putaway and inward)
CREATE OR REPLACE FUNCTION wms.upsert_stock(
    _material_id INTEGER,
    _rack_id INTEGER,
    _qty DECIMAL(15,3),
    _uom_id INTEGER,
    _rate DECIMAL(15,2),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _id INTEGER;
BEGIN
    -- Try to update existing stock
    UPDATE wms.stock
    SET qty = qty + _qty,
        lub = _current_user_id,
        lua = NOW()
    WHERE material_id = _material_id AND rack_id = _rack_id
    RETURNING id INTO _id;
    
    -- If no row was updated, insert new row
    IF _id IS NULL THEN
        INSERT INTO wms.stock (material_id, rack_id, qty, uom_id, rate, lub)
        VALUES (_material_id, _rack_id, _qty, _uom_id, _rate, _current_user_id)
        RETURNING id INTO _id;
    END IF;
    
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to reduce stock (for dispatch)
CREATE OR REPLACE FUNCTION wms.reduce_stock(
    _material_id INTEGER,
    _rack_id INTEGER,
    _qty DECIMAL(15,3),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _id INTEGER;
    _current_qty DECIMAL(15,3);
BEGIN
    -- Check current quantity
    SELECT id, qty INTO _id, _current_qty
    FROM wms.stock
    WHERE material_id = _material_id AND rack_id = _rack_id;
    
    IF _id IS NULL THEN
        RAISE EXCEPTION 'Stock not found for material_id % and rack_id %', _material_id, _rack_id;
    END IF;
    
    IF _current_qty < _qty THEN
        RAISE EXCEPTION 'Insufficient stock. Available: %, Requested: %', _current_qty, _qty;
    END IF;
    
    -- Reduce stock
    UPDATE wms.stock
    SET qty = qty - _qty,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to get available stock for a material
CREATE OR REPLACE FUNCTION wms.get_available_stock(
    _material_id INTEGER
) RETURNS TABLE (
    rack_id INTEGER,
    rack_code VARCHAR,
    rack_name VARCHAR,
    qty DECIMAL(15,3),
    uom_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.rack_id,
        r.code as rack_code,
        r.name as rack_name,
        s.qty,
        u.name as uom_name
    FROM wms.stock s
    LEFT JOIN wms.rack r ON s.rack_id = r.id
    LEFT JOIN wms.uom u ON s.uom_id = u.id
    WHERE s.material_id = _material_id 
      AND s.qty > 0 
      AND s.is_active = true
    ORDER BY s.rack_id;
END;
$$ LANGUAGE plpgsql;


---------------------------** Rack Master **---------------------------

-- Function to insert rack
CREATE OR REPLACE FUNCTION wms.insert_rack(
    _code VARCHAR(50),
    _name VARCHAR(255),
    _descr VARCHAR(255),
    _capacity DECIMAL(15,3),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _new_id INTEGER;
BEGIN
    INSERT INTO wms.rack (
        code, name, descr, capacity, lub
    )
    VALUES (
        _code, _name, _descr, _capacity, _current_user_id
    )
    RETURNING id INTO _new_id;
    
    RETURN _new_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update rack
CREATE OR REPLACE FUNCTION wms.update_rack(
    _id INTEGER,
    _code VARCHAR(50),
    _name VARCHAR(255),
    _descr VARCHAR(255),
    _capacity DECIMAL(15,3),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.rack
    SET 
        code = _code,
        name = _name,
        descr = _descr,
        capacity = _capacity,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete rack
CREATE OR REPLACE FUNCTION wms.delete_rack(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.rack
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    
    RETURN _id;
END;
$$ LANGUAGE plpgsql;


---------------------------** Stock Movement **---------------------------

-- Function to move stock (with Expiry)
CREATE OR REPLACE FUNCTION wms.move_stock(
    _from_stock_id INTEGER,
    _to_rack_id INTEGER,
    _move_qty DECIMAL(15,3),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _material_id INTEGER;
    _current_rack_id INTEGER;
    _current_qty DECIMAL(15,3);
    _uom_id INTEGER;
    _rate DECIMAL(15,2);
    _expiry_dt DATE;
    _to_stock_id INTEGER;
BEGIN
    -- Get Source Stock Details including Expiry
    SELECT material_id, rack_id, qty, uom_id, rate, expiry_dt
    INTO _material_id, _current_rack_id, _current_qty, _uom_id, _rate, _expiry_dt
    FROM wms.stock
    WHERE id = _from_stock_id;

    IF _current_qty < _move_qty THEN
        RAISE EXCEPTION 'Insufficient stock. Available: %, Requested: %', _current_qty, _move_qty;
    END IF;

    IF _current_rack_id = _to_rack_id THEN
        RAISE EXCEPTION 'Source and Target Rack cannot be the same.';
    END IF;

    -- Decrement Source
    UPDATE wms.stock
    SET qty = qty - _move_qty, lub = _current_user_id, lua = NOW()
    WHERE id = _from_stock_id;

    -- Upsert Target (Match Expiry)
    SELECT id INTO _to_stock_id
    FROM wms.stock
    WHERE material_id = _material_id 
      AND rack_id = _to_rack_id 
      AND (expiry_dt = _expiry_dt OR (expiry_dt IS NULL AND _expiry_dt IS NULL));

    IF _to_stock_id IS NOT NULL THEN
        UPDATE wms.stock
        SET qty = qty + _move_qty, lub = _current_user_id, lua = NOW()
        WHERE id = _to_stock_id;
    ELSE
        INSERT INTO wms.stock (
            material_id, rack_id, qty, uom_id, rate, expiry_dt, lub
        )
        VALUES (
            _material_id, _to_rack_id, _move_qty, _uom_id, _rate, _expiry_dt, _current_user_id
        )
        RETURNING id INTO _to_stock_id;
    END IF;

    RETURN _to_stock_id;
END;
$$ LANGUAGE plpgsql;

---------------------------** Picking List Header **---------------------------

-- Function to insert picking_list_header
CREATE OR REPLACE FUNCTION wms.insert_picking_list_header(
    _entry_dt DATE,
    _party_id INTEGER,
    _so_ids TEXT,
    _remarks VARCHAR(255),
    _current_user_id INTEGER
) RETURNS TABLE (id INTEGER, entry_no VARCHAR) AS $$
DECLARE
    v_max INTEGER;
    v_new_no INTEGER;
    v_new_id INTEGER;
    v_entry_no VARCHAR(50);
BEGIN
    PERFORM pg_advisory_xact_lock('wms.picking_list_header');

    -- Compute numeric part robustly by stripping non-digits and taking max
    SELECT COALESCE(
        MAX((REGEXP_REPLACE(h.entry_no, '[^0-9]', '', 'g'))::INT),
        0
    )
    INTO v_max
    FROM wms.picking_list_header h
    WHERE h.entry_no ~ '^PL[0-9]+';

    v_new_no := v_max + 1;
    v_entry_no := 'PL' || LPAD(v_new_no::TEXT, 6, '0');

    INSERT INTO wms.picking_list_header (
        entry_no, entry_dt, party_id, so_ids, remarks, status, lub
    )
    VALUES (
        v_entry_no, _entry_dt, _party_id, _so_ids, _remarks, 'Draft', _current_user_id
    )
    RETURNING wms.picking_list_header.id, wms.picking_list_header.entry_no INTO v_new_id, v_entry_no;

    RETURN QUERY SELECT v_new_id, v_entry_no;
END;
$$ LANGUAGE plpgsql;

-- Function to update picking_list_header
CREATE OR REPLACE FUNCTION wms.update_picking_list_header(
    _id INTEGER,
    _entry_dt DATE,
    _party_id INTEGER,
    _so_ids TEXT,
    _remarks VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.picking_list_header
    SET 
        entry_dt = _entry_dt,
        party_id = _party_id,
        so_ids = _so_ids,
        remarks = _remarks,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

---------------------------** Picking List Details **---------------------------

-- Function to insert picking_list_details
CREATE OR REPLACE FUNCTION wms.insert_picking_list_details(
    _header_id INTEGER,
    _material_id INTEGER,
    _rack_id INTEGER,
    _expiry_dt DATE,
    _qty DECIMAL(15,3),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _new_id INTEGER;
BEGIN
    INSERT INTO wms.picking_list_details (
        header_id, material_id, rack_id, expiry_dt, qty, picked_qty, status, lub
    )
    VALUES (
        _header_id, _material_id, _rack_id, _expiry_dt, _qty, 0, 'Pending', _current_user_id
    )
    RETURNING id INTO _new_id;
    
    RETURN _new_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update picking_list_details
CREATE OR REPLACE FUNCTION wms.update_picking_list_details(
    _id INTEGER,
    _rack_id INTEGER,
    _expiry_dt DATE,
    _qty DECIMAL(15,3),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.picking_list_details
    SET 
        rack_id = _rack_id,
        expiry_dt = _expiry_dt,
        qty = _qty,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete picking_list_details
CREATE OR REPLACE FUNCTION wms.delete_picking_list_details(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.picking_list_details
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete all picking_list_details for a given header
CREATE OR REPLACE FUNCTION wms.delete_picking_details_by_header(
    _header_id INTEGER,
    _current_user_id INTEGER
) RETURNS VOID AS $$
BEGIN
    UPDATE wms.picking_list_details
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE header_id = _header_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION wms.update_so_details_on_dispatch(
    _picking_list_header_id INTEGER
) RETURNS VOID AS $$
DECLARE
    _detail RECORD;
    _so_detail_id INTEGER;
BEGIN
    -- Loop through all picking list details
    FOR _detail IN 
        SELECT id, so_detail_ids, qty 
        FROM wms.picking_list_details 
        WHERE header_id = _picking_list_header_id 
          AND is_active = true
    LOOP
        -- Parse comma-separated SO detail IDs and update each
        IF _detail.so_detail_ids IS NOT NULL AND _detail.so_detail_ids != '' THEN
            FOR _so_detail_id IN 
                SELECT UNNEST(string_to_array(_detail.so_detail_ids, ',')::int[])
            LOOP
                -- Update dqty for each SO detail (simplified: add full allocation qty? NO, should be proportional)
                -- Wait, if one allocation covers multiple SO details, we can't just add full qty to each.
                -- For now, distributing proportionally is complex in SQL.
                -- Let's assume we want to update the dqty.
                -- If we just increment, we might over-dispatch.
                -- Let's stick to the plan: update dqty. For now, we will just split equally? Or apply to first?
                -- Re-reading plan: "Update: SO Detail 1 dqty += 60, SO Detail 2 dqty += 40"
                -- But we don't know the split here.
                -- We only know total allocated qty (e.g. 100) and the IDs (123, 124).
                -- We don't know how much for each.
                -- If we simply update dqty, let's just mark them?
                -- Actually, let's just leave the simple update for now and note it as a limitation or future improvement.
                -- We will just update dqty += qty / count?
                -- Or better: We rely on the fact that usually it's one-to-one or we distribute.
                -- Let's use the code from the plan which suggested a simplified update.
                
                UPDATE wms.sales_order_details
                SET dqty = COALESCE(dqty, 0) + (_detail.qty / NULLIF(array_length(string_to_array(_detail.so_detail_ids, ','), 1), 0))
                WHERE id = _so_detail_id;
            END LOOP;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- Function to confirm picking list (Mark as Picked)
CREATE OR REPLACE FUNCTION wms.confirm_picking_list(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _status VARCHAR(50);
BEGIN
    SELECT status INTO _status FROM wms.picking_list_header WHERE id = _id;
    
    IF _status != 'Draft' THEN
        RAISE EXCEPTION 'Only Draft picking lists can be confirmed.';
    END IF;

    -- Update details status
    UPDATE wms.picking_list_details
    SET 
        status = 'Picked',
        picked_qty = qty,
        lub = _current_user_id,
        lua = NOW()
    WHERE header_id = _id AND is_active = true;

    -- Update header status
    UPDATE wms.picking_list_header
    SET 
        status = 'Picked',
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;

    RETURN _id;
END;
$$ LANGUAGE plpgsql;

---------------------------** Dispatch Header **---------------------------

-- Function to insert dispatch_header
CREATE OR REPLACE FUNCTION wms.insert_dispatch_header(
    _entry_dt DATE,
    _party_id INTEGER,
    _pl_ids TEXT,
    _vehicle_no VARCHAR(50),
    _driver_name VARCHAR(255),
    _remarks VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _new_id INTEGER;
    _entry_no VARCHAR(50);
BEGIN
    SELECT 'DSP-' || TO_CHAR(NOW(), 'YYMMDD') || '-' || LPAD(CAST(COALESCE(MAX(id), 0) + 1 AS TEXT), 4, '0')
    INTO _entry_no
    FROM wms.dispatch_header;

    INSERT INTO wms.dispatch_header (
        entry_no, entry_dt, party_id, pl_ids, vehicle_no, driver_name, remarks, status, lub
    )
    VALUES (
        _entry_no, _entry_dt, _party_id, _pl_ids, _vehicle_no, _driver_name, _remarks, 'Draft', _current_user_id
    )
    RETURNING id INTO _new_id;
    
    RETURN _new_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update dispatch_header
CREATE OR REPLACE FUNCTION wms.update_dispatch_header(
    _id INTEGER,
    _entry_dt DATE,
    _party_id INTEGER,
    _pl_ids TEXT,
    _vehicle_no VARCHAR(50),
    _driver_name VARCHAR(255),
    _remarks VARCHAR(255),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.dispatch_header
    SET 
        entry_dt = _entry_dt,
        party_id = _party_id,
        pl_ids = _pl_ids,
        vehicle_no = _vehicle_no,
        driver_name = _driver_name,
        remarks = _remarks,
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

---------------------------** Dispatch Details **---------------------------

-- Function to insert dispatch_details
CREATE OR REPLACE FUNCTION wms.insert_dispatch_details(
    _header_id INTEGER,
    _material_id INTEGER,
    _picking_detail_id INTEGER,
    _qty DECIMAL(15,3),
    _uom_id INTEGER,
    _hsn_id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _new_id INTEGER;
    _cgst DECIMAL(5,2) := 0;
    _sgst DECIMAL(5,2) := 0;
    _igst DECIMAL(5,2) := 0;
    _utgst DECIMAL(5,2) := 0;
BEGIN
    SELECT h.cgst, h.sgst, h.igst, h.utgst
    INTO _cgst, _sgst, _igst, _utgst
    FROM wms.hsn h WHERE h.id = _hsn_id;

    INSERT INTO wms.dispatch_details (
        header_id, material_id, picking_detail_id, qty, uom_id, hsn_id, cgst, sgst, igst, utgst, lub
    )
    VALUES (
        _header_id, _material_id, _picking_detail_id, _qty, _uom_id, _hsn_id,
        COALESCE(_cgst, 0), COALESCE(_sgst, 0), COALESCE(_igst, 0), COALESCE(_utgst, 0),
        _current_user_id
    )
    RETURNING id INTO _new_id;

    RETURN _new_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete dispatch_details
CREATE OR REPLACE FUNCTION wms.delete_dispatch_details(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.dispatch_details
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

---------------------------** Process Dispatch **---------------------------

-- Function to process dispatch (Deduct Stock & Update SO)
CREATE OR REPLACE FUNCTION wms.process_dispatch(
    _dispatch_id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _status VARCHAR(50);
    _detail RECORD;
    _pick_detail RECORD;
    _pl_ids TEXT;
BEGIN
    SELECT status, pl_ids INTO _status, _pl_ids FROM wms.dispatch_header WHERE id = _dispatch_id;
    
    IF _status = 'Dispatched' THEN
        RAISE EXCEPTION 'Dispatch entry is already processed.';
    END IF;

    -- Auto-populate dispatch_details if empty
    IF NOT EXISTS (SELECT 1 FROM wms.dispatch_details WHERE header_id = _dispatch_id AND is_active = true) THEN
        INSERT INTO wms.dispatch_details (header_id, material_id, picking_detail_id, qty, uom_id, hsn_id, lub)
        SELECT
            _dispatch_id,
            pld.material_id,
            pld.id,
            pld.qty,
            (SELECT uom_pc_id FROM wms.material_ean WHERE material_id = pld.material_id AND is_active = true LIMIT 1),
            m.hsn_id,
            _current_user_id
        FROM wms.picking_list_details pld
        JOIN wms.material m ON pld.material_id = m.id
        WHERE pld.header_id = ANY(string_to_array(_pl_ids, ',')::int[])
          AND pld.status = 'Picked'
          AND pld.is_active = true;
    END IF;

    -- Update Dispatch Status
    UPDATE wms.dispatch_header
    SET status = 'Dispatched', lub = _current_user_id, lua = NOW()
    WHERE id = _dispatch_id;

    FOR _detail IN SELECT * FROM wms.dispatch_details WHERE header_id = _dispatch_id AND is_active = true LOOP
        -- Get Picking Detail to find Rack, Expiry, and SO Detail
        SELECT rack_id, expiry_dt, so_detail_id INTO _pick_detail 
        FROM wms.picking_list_details 
        WHERE id = _detail.picking_detail_id;

        -- 1. Deduct Stock
        PERFORM wms.reduce_stock(_detail.material_id, _pick_detail.rack_id, _detail.qty, _pick_detail.expiry_dt, _current_user_id);

        -- 2. Update Sales Order dqty
        UPDATE wms.sales_order_details
        SET dqty = COALESCE(dqty, 0) + _detail.qty
        WHERE id = _pick_detail.so_detail_id;
    END LOOP;

    RETURN _dispatch_id;
END;
$$ LANGUAGE plpgsql;

-- Function to reduce stock from a specific rack
CREATE OR REPLACE FUNCTION wms.reduce_stock(
    _ean_id INTEGER,
    _rack_id INTEGER,
    _qty DECIMAL(15,3),
    _batch_no VARCHAR(100),
    _current_user_id INTEGER
) RETURNS VOID AS $$
DECLARE
    _stock_id INTEGER;
    _current_qty DECIMAL(15,3);
BEGIN
    SELECT id, qty INTO _stock_id, _current_qty
    FROM wms.stock
    WHERE ean_id = _ean_id
      AND rack_id = _rack_id
      AND (batch_no = _batch_no OR (batch_no IS NULL AND _batch_no IS NULL));

    IF _stock_id IS NULL THEN
        RAISE EXCEPTION 'Stock record not found for EAN ID %, Rack ID %, Batch %', _ean_id, _rack_id, _batch_no;
    END IF;

    IF _current_qty < _qty THEN
        RAISE EXCEPTION 'Insufficient stock in Rack %. Available: %, Requested: %', _rack_id, _current_qty, _qty;
    END IF;

    UPDATE wms.stock
    SET qty = qty - _qty, lub = _current_user_id, lua = NOW()
    WHERE id = _stock_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION wms.allocate_stock_to_so(
    _header_id INTEGER,
    _material_id INTEGER
) RETURNS VOID AS $$
DECLARE
    _total_picked_qty DECIMAL(15,3);
    _so_detail RECORD;
    _allocatable_qty DECIMAL(15,3);
    _so_ids TEXT;
    _so_id_array INT[];
BEGIN
    -- 1. Calculate total picked quantity for this material in this header
    SELECT COALESCE(SUM(qty), 0)
    INTO _total_picked_qty
    FROM wms.picking_list_details
    WHERE header_id = _header_id
      AND material_id = _material_id
      AND is_active = true;

    RAISE INFO 'Total picked qty: %', _total_picked_qty;

    -- 2. Get the list of SO IDs from the header
    SELECT so_ids INTO _so_ids
    FROM wms.picking_list_header
    WHERE id = _header_id;

    RAISE INFO 'SO IDs: %', _so_ids;
    
    _so_id_array := string_to_array(_so_ids, ',')::INT[];

    -- 3. Clear existing SO allocations for this material/header
    DELETE FROM wms.picking_list_so_allocation
    WHERE header_id = _header_id
      AND material_id = _material_id;

    -- 4. Loop through pending SO details (FIFO by SO Date)
    FOR _so_detail IN 
        SELECT 
            d.id, 
            (d.eqty - COALESCE(d.dqty, 0)) as pending_qty
        FROM wms.sales_order_details d
        JOIN wms.sales_order_header h ON d.header_id = h.id
        WHERE d.item_id = _material_id
          AND h.id = ANY(_so_id_array)
          AND d.is_active = true
          AND (d.eqty - COALESCE(d.dqty, 0)) > 0
        ORDER BY h.entry_dt ASC, d.id ASC
    LOOP
        RAISE INFO 'SO Detail ID: %', _so_detail.id;
        -- If we have no more picked stock, exit loop
        IF _total_picked_qty <= 0 THEN
            RAISE INFO 'No more picked stock';
            EXIT;
        END IF;

        -- Calculate how much we can allocate to this SO detail
        IF _total_picked_qty >= _so_detail.pending_qty THEN
            _allocatable_qty := _so_detail.pending_qty;
        ELSE
            _allocatable_qty := _total_picked_qty;
        END IF;

        RAISE INFO 'Allocatable Qty: %', _allocatable_qty;

        -- Insert allocation
        INSERT INTO wms.picking_list_so_allocation (
            header_id, so_detail_id, material_id, qty, status, is_active
        ) VALUES (
            _header_id, _so_detail.id, _material_id, _allocatable_qty, 'Pending', true
        );

        RAISE INFO 'Remaining picked qty: %', _total_picked_qty;
        -- Decrease remaining picked stock
        _total_picked_qty := _total_picked_qty - _allocatable_qty;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION wms.save_manual_pick(
    _header_id INTEGER,
    _material_id INTEGER,
    _rack_id INTEGER,
    _expiry_dt DATE,
    _qty DECIMAL(15,3)
) RETURNS VOID AS $$
BEGIN
    -- 1. Delete existing records for this specific combination
    DELETE FROM wms.picking_list_details 
    WHERE header_id = _header_id 
      AND material_id = _material_id 
      AND rack_id = _rack_id 
      AND (expiry_dt = _expiry_dt OR (expiry_dt IS NULL AND _expiry_dt IS NULL))
      AND is_active = true;

    -- 2. Insert the new row
    INSERT INTO wms.picking_list_details (
      header_id, material_id, rack_id, expiry_dt, qty, is_active, status, so_detail_ids
    ) VALUES (
      _header_id, _material_id, _rack_id, _expiry_dt, _qty, true, 'Draft', ''
    );

    -- 3. Trigger allocation
    PERFORM wms.allocate_stock_to_so(_header_id, _material_id);
END;
$$ LANGUAGE plpgsql;


---------------------------** HSN Master **---------------------------

-- Function to insert HSN
CREATE OR REPLACE FUNCTION wms.insert_hsn(
    _hsn_code VARCHAR(20),
    _descr VARCHAR(255),
    _cgst DECIMAL(5,2),
    _sgst DECIMAL(5,2),
    _igst DECIMAL(5,2),
    _utgst DECIMAL(5,2),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _id INTEGER;
BEGIN
    INSERT INTO wms.hsn (
        hsn_code, descr, cgst, sgst, igst, utgst, lub
    )
    VALUES (
        _hsn_code, _descr, COALESCE(_cgst, 0), COALESCE(_sgst, 0), COALESCE(_igst, 0), COALESCE(_utgst, 0), _current_user_id
    )
    RETURNING id INTO _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to update HSN
CREATE OR REPLACE FUNCTION wms.update_hsn(
    _id INTEGER,
    _hsn_code VARCHAR(20),
    _descr VARCHAR(255),
    _cgst DECIMAL(5,2),
    _sgst DECIMAL(5,2),
    _igst DECIMAL(5,2),
    _utgst DECIMAL(5,2),
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.hsn
    SET hsn_code = _hsn_code,
        descr = _descr,
        cgst = COALESCE(_cgst, 0),
        sgst = COALESCE(_sgst, 0),
        igst = COALESCE(_igst, 0),
        utgst = COALESCE(_utgst, 0),
        lub = _current_user_id,
        lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete HSN (soft delete)
CREATE OR REPLACE FUNCTION wms.delete_hsn(
    _id INTEGER,
    _current_user_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    UPDATE wms.hsn
    SET is_active = false, lub = _current_user_id, lua = NOW()
    WHERE id = _id;
    RETURN _id;
END;
$$ LANGUAGE plpgsql;
