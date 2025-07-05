INSERT INTO administration.user (username, email, first_name, last_name, password, reports_to, lub) VALUES
('admin', 'LQrGq@example.com', 'Admin', 'Admin', 'admin', 0, 1);

INSERT INTO administration.role (name, description, lub) VALUES
('super_admin', 'desc', 1);

INSERT INTO administration.user_role (user_id, role_id, lub) VALUES
(1, 1, 1);

INSERT INTO administration.resource (name, list_config_file, parent_id, lub) VALUES
('Main Menu', NULL, 0, 1),
('Administration', NULL, 1, 1),
('Master Data', NULL, 1, 1),
('Sales', NULL, 1, 1),
('Purchase', NULL, 1, 1),
('User Management', 'list-users', 2, 1),
('Role Management', 'list-roles', 2, 1),
('Geo Location', NULL, 3, 1),
('Warehouse Management', NULL, 3, 1),
('Party Management', NULL, 3, 1),
('Vendor Management', NULL, 3, 1),
('Item Management', NULL, 3, 1),
('Sales Order', 'list-sales-orders', 4, 1),
('Picking List', 'list-picking-lists', 4, 1),
('Dispatch', 'list-dispatches', 4, 1),
('Sales Return', 'list-sales-returns', 4, 1),
('Purchase Order', 'list-purchase-orders', 5, 1),
('Inward', 'list-inwards', 5, 1),
('Putaway', 'list-putaways', 5, 1),
('Purchase Return', 'list-purchase-returns', 5, 1),
('Country Master', 'list-countries', 8, 1),
('State Master', 'list-states', 8, 1),
('City Master', 'list-cities', 8, 1),
('District Master', 'list-districts', 8, 1),
('Rack Master', 'list-racks', 9, 1),
('Party Master', 'list-parties', 10, 1),
('Party Category Master', 'list-party-categories', 10, 1),
('Vendor Master', 'list-vendors', 11, 1),
('Item Master', 'list-items', 12, 1),
('Item Category Master', 'list-item-categories', 12, 1),
('Item Brand Master', 'list-item-brands', 12, 1),
('UOM Master', 'list-uoms', 12, 1),
('Unit Conversion Master', 'list-unit-conversions', 12, 1);






---
--- main_menu
---   |
---   +-- Administration
---   |   |
---   |   +-- User Management
---   |   |
---   |   +-- Role Management
---   |   |
---   |   +-- Access Grant Management
---   |   |
---   |   +-- Resource Management
---   |
---   +-- Master Data
---   |   |
---   |   +-- Geo Location
---   |   |   |
---   |   |   +-- Country Master
---   |   |   |
---   |   |   +-- State Master
---   |   |   |
---   |   |   +-- City Master
---   |   |   |
---   |   |   +-- District Master
---   |   |
---   |   +-- Warehouse Management
---   |   |   |
---   |   |   +-- Rack Master
---   |   |
---   |   +-- Party Management
---   |   |   |
---   |   |   +-- Party Master
---   |   |   |
---   |   |   +-- Party Category Master
---   |   |
---   |   +-- Vendor Management
---   |   |   |
---   |   |   +-- Vendor Master
---   |   |
---   |   +-- Item Management
---   |   |   |
---   |   |   +-- Item Master
---   |   |   |
---   |   |   +-- Item Category Master
---   |   |   |
---   |   |   +-- Item Brand Master
---   |   |   |
---   |   |   +-- UOM Master
---   |   |   |
---   |   |   +-- Unit Conversion Master
---   |   |
---   +-- Sales
---   |   |
---   |   +-- Sales Order
---   |   |
---   |   +-- Picking List
---   |   |
---   |   +-- Dispatch
---   |   |
---   |   +-- Sales Return
---   |
---   +-- Purchase
---   |   |
---   |   +-- Purchase Order
---   |   |
---   |   +-- Inward
---   |   |
---   |   +-- Putaway
---   |   |
---   |   +-- Purchase Return
