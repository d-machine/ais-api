INSERT INTO administration.user (username, email, first_name, last_name, password, reports_to, lub) VALUES
('admin', 'LQrGq@example.com', 'Admin', 'Admin', 'admin', 0, 1);

INSERT INTO administration.role (name, description, lub) VALUES
('super_admin', 'desc', 1);

INSERT INTO administration.user_role (user_id, role_id, lub) VALUES
(1, 1, 1);

INSERT INTO administration.resource (id, name, list_config_file, parent_id, lub) VALUES
(1, 'Main Menu', NULL, 0, 1),
-- The main menu is the root of the hierarchy, with no parent.
(2, 'Administration', NULL, 1, 1),
(3, 'Master Data', NULL, 1, 1),
(4, 'Sales', NULL, 1, 1),
(5, 'Purchase', NULL, 1, 1),
(6, 'Reports', NULL, 1, 1),
-- 2 - 20 are for top level resources.
(21, 'User Management', 'list-users', 2, 1),
(22, 'Role Management', 'list-roles', 2, 1),
-- 21 - 30 are for direct children of Administration.
(31, 'Geo Location', NULL, 3, 1),
(32, 'Warehouse Management', NULL, 3, 1),
(33, 'Party Management', NULL, 3, 1),
(34, 'Vendor Management', NULL, 3, 1),
(35, 'Item Management', NULL, 3, 1),
-- 31 - 40 are for direct children of Master Data.
(41, 'Country Master', 'list-countries', 31, 1),
(42, 'State Master', 'list-states', 31, 1),
(43, 'City Master', 'list-cities', 31, 1),
(44, 'District Master', 'list-districts', 31, 1),
(45, 'City District Master', 'list-city-districts', 31, 1),
-- 41 - 50 are for Geo location.
(51, 'Rack Master', 'list-racks', 32, 1),
-- 51 - 60 are for Warehouse Management.
(61, 'Party Master', 'list-parties', 33, 1),
(62, 'Party Category Master', 'list-party-categories', 33, 1),
(63, 'Party Broker Master', 'list-brokers', 33, 1),
-- 61 - 70 are for Party Management.
(71, 'Vendor Master', 'list-vendors', 34, 1),
(72, 'Vendor Category Master', 'list-vendor-categories', 34, 1),
(73, 'Vendor Broker Master', 'list-vendor-brokers', 34, 1),
-- 71 - 80 are for Vendor Management.
(81, 'Item Master', 'list-items', 35, 1),
(82, 'Item Category Master', 'list-item-categories', 35, 1),
(83, 'Item Brand Master', 'list-item-brands', 35, 1),
(84, 'UOM Master', 'list-uoms', 35, 1),
(85, 'Unit Conversion Master', 'list-unit-conversions', 35, 1),
-- 81 - 90 are for Item Management.
(91, 'Sales Order', 'list-sales-orders', 4, 1),
(92, 'Picking List', 'list-picking-lists', 4, 1),
(93, 'Dispatch', 'list-dispatches', 4, 1),
(94, 'Sales Return', 'list-sales-returns', 4, 1),
-- 91 - 100 are for Sales.
(101, 'Purchase Order', 'list-purchase-orders', 5, 1),
(102, 'Inward', 'list-inwards', 5, 1),
(103, 'Putaway', 'list-putaways', 5, 1),
(104, 'Purchase Return', 'list-purchase-returns', 5, 1)
-- 101 - 110 are for Purchase.
;

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
