CREATE OR REPLACE VIEW user_list_view AS
SELECT u.id as user_id, u.username as username,
    u.email as email, u.first_name as first_name, u.last_name as last_name,
    TRIM(CONCAT(u.first_name, ' ', u.last_name)) as full_name,
    string_agg(r.name, ', ') as roles, string_agg(r.role_id::text, ', ') as role_ids,
    string_agg(ur.id::text, ', ') as user_role_ids,
    TRIM(CONCAT(rt.first_name, ' ', rt.last_name)) as reports_to,
    u.lub as lub, u.lua as lua
    FROM user u
    LEFT JOIN user rt ON u.reports_to = rt.id
    LEFT JOIN user_role ur ON u.id = ur.user_id
    LEFT JOIN role r ON ur.role_id = r.id
    GROUP BY u.id, u.username, u.email, u.first_name, u.last_name,
    rt.first_name, rt.last_name,
    u.lub, u.lua;

