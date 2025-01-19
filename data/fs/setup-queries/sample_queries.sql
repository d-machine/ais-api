SELECT * from administration.user;
SELECT * from administration.role;
-- SELECT * from administration.user_role;
-- SELECT * from administration.access_grants;
SELECT * from administration.resource_access_role;
SELECT * from administration.resource;

delete from administration.user_history;

DROP TABLE IF EXISTS administration.refresh_token;
DROP TABLE IF EXISTS administration.refresh_token_history;
DROP FUNCTION IF EXISTS administration.refresh_token_trigger;
DROP FUNCTION IF EXISTS administration.delete_refresh_token;

CREATE TABLE IF NOT EXISTS administration.resource_hierarchy_closure_history (
    history_id SERIAL PRIMARY KEY,
    resource_hierarchy_closure_id INTEGER,
    ancestor_id INTEGER NOT NULL,
    descendant_id INTEGER NOT NULL,
    depth INTEGER NOT NULL,
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES administration.user(id)
);

insert into administration.resource (name, description, last_updated_by) VALUES
('Main Menu', 'Main menu placeholder', 3);

insert into administration.resource (name, description, last_updated_by) VALUES
('Admin Panel', 'Admin Panel', 3);

insert into administration.resource (name, description, last_updated_by) VALUES
('User Panel', 'User Panel', 3);

insert into administration.resource (name, description, last_updated_by) VALUES
('Role Panel', 'Role Panel', 3);


insert into administration.user (username, password, reportsto, last_updated_by) VALUES
('sumit', 'sumit', 3, 3);
insert into administration.user (username, password, reportsto, last_updated_by) VALUES
('sachin', 'sachin', 3, 3);
insert into administration.user (username, password, reportsto, last_updated_by) VALUES
('shalu', 'shalu', 4, 3);
insert into administration.user (username, password, reportsto, last_updated_by) VALUES
('jyoti', 'jyoti', 5, 3);
insert into administration.user (username, password, reportsto, last_updated_by) VALUES
('chavi', 'chavi', 7, 3);

insert into administration.role (name, description, team, department, last_updated_by) values
('super_admin', 'desc', 'ais', 'dev', 3);
insert into administration.role (name, description, team, department, last_updated_by) values
('manager', 'desc', 'ais', 'dev', 3);
insert into administration.role (name, description, team, department, last_updated_by) values
('assistant_manager', 'desc', 'ais', 'dev', 3);
insert into administration.role (name, description, team, department, last_updated_by) values
('salesman', 'desc', 'ais', 'dev', 3);

insert into administration.user_role (user_id, role_id, last_updated_by) VALUES
(3, 1, 3),
(4, 2, 3),
(5, 2, 3),
(6, 3, 3),
(7, 3, 3),
(8, 3, 3);

insert into administration.user_role (user_id, role_id, last_updated_by) VALUES
(7, 4, 3);

update administration.user_role
set role_id = 4
where user_id = 8

insert into administration.resource (name, parent_id) values
('main_menu', 0);

insert into administration.resource (name, parent_id) values
('r1', 1),
('r2', 1),
('r3', 2),
('r4', 2),
('r5', 3),
('r6', 3);

insert into administration.resource_access_role (role_id, resource_id, access_type, access_level, last_updated_by) VALUES
(2, 4, 'READ', 'ALL', 3),
(2, 5, 'READ', 'ALL', 3),
(2, 6, 'READ', 'ALL', 3),
(2, 7, 'READ', 'ALL', 3);

insert into administration.resource_access_role (role_id, resource_id, access_type, access_level, last_updated_by) VALUES
(3, 4, 'READ', 'ALL', 3),
(3, 5, 'READ', 'ALL', 3);

-- SELECT DISTINCT r.id as role_id, r.name as role_name, NULL::text as access_type
-- FROM administration.user_role ur
-- JOIN administration.role r ON ur.role_id = r.id
-- WHERE ur.user_id = 5

-- UNION ALL

-- SELECT r.id as role_id, r.name as role_name, ag.access_type::text
-- FROM administration.access_grants ag
-- JOIN administration.user_role ur ON ur.user_id = ag.target_id
-- JOIN administration.role r ON ur.role_id = r.id
-- WHERE ag.user_id = 5;


-- WITH RECURSIVE resource_hierarchy AS (
--         SELECT DISTINCT rar.resource_id
--         FROM administration.resource_access_role rar
--         WHERE rar.role_id = 3

--         UNION ALL

--         SELECT distinct r.parent_id as resource_id
--         FROM administration.resource r
--         INNER JOIN resource_hierarchy eh ON r.id = eh.resource_id
--       )
--       SELECT resource_id FROM resource_hierarchy;



WITH RECURSIVE roles as (
    SELECT DISTINCT r.id as role_id, r.name as role_name, NULL::text as access_type
    FROM administration.user_role ur
    JOIN administration.role r ON ur.role_id = r.id
    WHERE ur.user_id = 5

    UNION ALL

    SELECT r.id as role_id, r.name as role_name, ag.access_type::text
    FROM administration.access_grants ag
    JOIN administration.user_role ur ON ur.user_id = ag.target_id
    JOIN administration.role r ON ur.role_id = r.id
    WHERE ag.user_id = 5
),
resource_hierarchy AS (
    SELECT DISTINCT rar.resource_id,  r.role_id, r.role_name, rar.access_level,
    COALESCE(r.access_type::text, rar.access_type::text) as access_type
    FROM administration.resource_access_role rar
    JOIN roles r ON r.role_id = rar.role_id

    UNION ALL

    SELECT distinct r.parent_id as resource_id, rh.role_id,
    rh.role_name, rh.access_level, rh.access_type
    FROM administration.resource r
    INNER JOIN resource_hierarchy rh ON r.id = rh.resource_id
)
SELECT rh.*, r.parent_id FROM resource_hierarchy rh
    JOIN administration.resource r ON r.id = rh.resource_id;