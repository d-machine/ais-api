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
                      reports_to, last_updated_by)
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
        reports_to = reports_to, last_updated_by = current_user_id
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
    SET password = password, last_updated_by = current_user_id
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
    INSERT INTO administration.role (name, description, last_updated_by)
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
    SET name = name, description = description, last_updated_by = current_user_id
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
    INSERT INTO administration.claim (role_id, resource_id, access_type_ids, access_level_id, last_updated_by)
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
    SET role_id = role_id, resource_id = resource_id, access_type_ids = access_type_ids, access_level_id = access_level_id, last_updated_by = current_user_id
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
    INSERT INTO administration.resource (name, list_config_file, parent_id, last_updated_by)
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
    SET name = name, list_config_file = list_config_file, parent_id = parent_id, last_updated_by = current_user_id
    WHERE id = resource_id;
    RETURN resource_id;
END;
$$ LANGUAGE plpgsql;


---------------------------** Country Master **---------------------------

-- Function to delete country_master
CREATE OR REPLACE FUNCTION wms.delete_country_master(
    country_master_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    -- Insert into history before deletion
    INSERT INTO wms.country_master_history (
        country_master_id,
        country_name,
        country_code,
        operation, operation_at, operation_by
    )
    SELECT 
        id,
        country_name,
        country_code,
        'DELETE', NOW(), deleted_by_user_id
    FROM wms.country_master
    WHERE id = country_master_id_to_delete;

    -- Delete the country_master
    DELETE FROM wms.country_master 
    WHERE id = country_master_id_to_delete;
END;
$$ LANGUAGE plpgsql;
