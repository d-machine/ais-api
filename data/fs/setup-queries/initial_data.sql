INSERT INTO administration.user (username, email, first_name, last_name, password, reports_to, lub) VALUES
('admin',     'admin@example.com',     'Admin',  'User',   'admin',     0, 1),
('picker1',   'picker1@example.com',   'Ravi',   'Kumar',  '$2b$10$paRg2t.YSff9..ms/5HAGu2jOQyPvyffISK1APoqlkarMoUhPD1xy', 0, 1),
('picker2',   'picker2@example.com',   'Suresh', 'Mehta',  '$2b$10$5KBiawWtflm7OwiYtZH8tO0Qm3ckX5Wmo.mZA/y4ZeCo2OcUfJVWe', 0, 1),
('picker3',   'picker3@example.com',   'Arjun',  'Singh',  '$2b$10$u3Vcxns7kEt651leDZCaBeGYSVQINZ6Zv30JUJhWaIC0WQNTi407y', 0, 1),
('picker4',   'picker4@example.com',   'Deepak', 'Verma',  '$2b$10$NnRyPYa9Jt50URAjh.HXoeGGrKlyPN0PO7WlfspErlKsiG27RPzj2', 0, 1),
('delivery1', 'delivery1@example.com', 'Ramesh', 'Yadav',  '$2b$10$e6RwEaAvNQunv8KQj2n2T.WmzXr4nUlqzcI8ZCNc7a4fKn7/lq7/C', 0, 1),
('delivery2', 'delivery2@example.com', 'Mohan',  'Gupta',  '$2b$10$n4DhOHXpzWebJiLGkJwqg.f7WIMTI4V8I5.zCXhSQ2GWJQoQRqNZe', 0, 1),
('delivery3', 'delivery3@example.com', 'Vikram', 'Sharma', '$2b$10$85bWrER4dWkkaJtR1HfZz.8jaUb.40lLsSw.RT05wtiraA7xwdQt6', 0, 1),
('delivery4', 'delivery4@example.com', 'Sanjay', 'Patil',  '$2b$10$iK9TfiMjJmC8siWRWI8L..TbeuD0DvyCFzJivPDJCW3zFd6oH1YWm', 0, 1);

INSERT INTO administration.role (name, descr, lub) VALUES
('super_admin',         'Full system access',                   1),
('picker',              'Warehouse picker — mobile app access', 1),
('delivery_personnel',  'Delivery driver — mobile app access',  1);

INSERT INTO administration.user_role (user_id, role_id, lub) VALUES
(1, 1, 1),  -- admin → super_admin
(2, 2, 1),  -- picker1 → picker
(3, 2, 1),  -- picker2 → picker
(4, 2, 1),  -- picker3 → picker
(5, 2, 1),  -- picker4 → picker
(6, 3, 1),  -- delivery1 → delivery_personnel
(7, 3, 1),  -- delivery2 → delivery_personnel
(8, 3, 1),  -- delivery3 → delivery_personnel
(9, 3, 1);  -- delivery4 → delivery_personnel

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
(46, 'Address Master', 'list-addresses', 31, 1),
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
(81, 'Material Master', 'list-materials', 35, 1),
(82, 'Material Category Master', 'list-item-categories', 35, 1),
(83, 'Material Brand Master', 'list-item-brands', 35, 1),
(84, 'UOM Master', 'list-uoms', 35, 1),
(85, 'UOM Conversion Master', 'list-uom-conversions', 35, 1),
(86, 'HSN Master', 'list-hsn', 35, 1),
-- 81 - 90 are for Item Management.
(91, 'Sales Order', 'list-sales-orders', 4, 1),
(92, 'Picking List', 'list-picking-lists', 4, 1),
(93, 'Dispatch', 'list-dispatches', 4, 1),
(94, 'Sales Return', 'list-sales-returns', 4, 1),
-- 91 - 100 are for Sales.
(101, 'Purchase Order', 'list-purchase-orders', 5, 1),
(102, 'Inward', 'list-inwards', 5, 1),
(103, 'Putaway', 'list-putaways', 5, 1),
(104, 'Purchase Return', 'list-purchase-returns', 5, 1),
-- 101 - 110 are for Purchase.
(111, 'Transport', 'list-transports', 3, 1),
-- Mobile app resources
(7, 'Mobile', NULL, 1, 1),
(120, 'Mobile Picker',   'mobile-dispatch-list',          7, 1),
(121, 'Mobile Delivery', 'mobile-dispatch-delivery-list', 7, 1)
;

-- Mark mobile resources
UPDATE administration.resource SET is_mobile = true WHERE id IN (120, 121);

-- Claims: picker role → mobile_picker resource; delivery_personnel → mobile_delivery resource
INSERT INTO administration.claim (role_id, resource_id, access_type_ids, access_level_id, lub) VALUES
(2, 120, 'ADD,EDIT,READ', 'GLOBAL', 1),  -- picker → mobile-dispatch-list
(3, 121, 'ADD,EDIT,READ', 'GLOBAL', 1);  -- delivery_personnel → mobile-dispatch-delivery-list

INSERT INTO wms.status_code (entity, code, label) VALUES
-- Purchase Order
('PO',     0,  'Draft'),
('PO',     10, 'Inwarded Partial'),
('PO',     20, 'Inward Completed'),
('PO',     50, 'Issue Raised'),
-- Inward
('INWARD', 0,  'Draft'),
('INWARD', 20, 'Processed'),
('INWARD', 50, 'Issue Raised'),
-- Sales Order
('SO',     0,  'Draft'),
('SO',     10, 'Dispatched Partial'),
('SO',     20, 'Dispatched Fully'),
('SO',     50, 'Issue Raised'),
-- Picking List
('PL',     0,  'Draft'),
('PL',     10, 'Assigned'),
('PL',     20, 'Picked'),
('PL',     50, 'Issue Raised');

INSERT INTO wms.country (name, code, lub) VALUES
('India', 'IN', 1);

INSERT INTO wms.state (name, code, state_type, country_id, lub) VALUES
('Haryana', 1, 'STATE', (SELECT id FROM wms.country WHERE code = 'IN'), 1);

INSERT INTO wms.client_config (state_id, lub) VALUES
((SELECT id FROM wms.state WHERE name = 'Haryana'), 1);

INSERT INTO wms.city (name, code, lub) VALUES
('Gurgaon', 'GGN', 1);

INSERT INTO wms.district (name, code, lub) VALUES
('Gurgaon', 'GGN', 1);

INSERT INTO wms.city_district (city_id, district_id, state_id, lub) VALUES
(
  (SELECT id FROM wms.city WHERE code = 'GGN'),
  (SELECT id FROM wms.district WHERE code = 'GGN'),
  (SELECT id FROM wms.state WHERE name = 'Haryana'),
  1
);

INSERT INTO wms.item_category (name, lub) VALUES
('MC1', 1);

INSERT INTO wms.item_brand (brand_name, category_id, lub) VALUES
('MB1', (SELECT id FROM wms.item_category WHERE name = 'MC1'), 1);

INSERT INTO wms.hsn (hsn_code, cgst, sgst, igst, utgst, lub) VALUES
('HSN1',  2.5, 2.5, 6, 2.5, 1),
('HSN2',  2.5, 2.5, 6, 2.5, 1),
('HSN3',  2.5, 2.5, 6, 2.5, 1),
('HSN4',  2.5, 2.5, 6, 2.5, 1),
('HSN5',  2.5, 2.5, 6, 2.5, 1),
('HSN6',  2.5, 2.5, 6, 2.5, 1),
('HSN7',  2.5, 2.5, 6, 2.5, 1),
('HSN8',  2.5, 2.5, 6, 2.5, 1),
('HSN9',  2.5, 2.5, 6, 2.5, 1),
('HSN10', 2.5, 2.5, 6, 2.5, 1);

INSERT INTO wms.rack (code, name, lub) VALUES
('R00', 'DEFAULT', 1);

INSERT INTO wms.party_category (name, lub) VALUES
('PC1', 1);

INSERT INTO wms.vendor_category (name, lub) VALUES
('VC1', 1);

INSERT INTO wms.uom (name, lub) VALUES
('PCS', 1),
('BOX24', 1);

INSERT INTO wms.uom_conversion (uom_id_each, uom_id_case, no_of_pcs, lub) VALUES
(
  (SELECT id FROM wms.uom WHERE name = 'PCS'),
  (SELECT id FROM wms.uom WHERE name = 'BOX24'),
  24,
  1
);

INSERT INTO wms.material (name, descr, category_id, brand_id, hsn_id, lub) VALUES
('MAT-001', 'Material 001', (SELECT id FROM wms.item_category WHERE name = 'MC1'), (SELECT id FROM wms.item_brand WHERE brand_name = 'MB1'), (SELECT id FROM wms.hsn WHERE hsn_code = 'HSN1'),  1),
('MAT-002', 'Material 002', (SELECT id FROM wms.item_category WHERE name = 'MC1'), (SELECT id FROM wms.item_brand WHERE brand_name = 'MB1'), (SELECT id FROM wms.hsn WHERE hsn_code = 'HSN2'),  1),
('MAT-003', 'Material 003', (SELECT id FROM wms.item_category WHERE name = 'MC1'), (SELECT id FROM wms.item_brand WHERE brand_name = 'MB1'), (SELECT id FROM wms.hsn WHERE hsn_code = 'HSN3'),  1),
('MAT-004', 'Material 004', (SELECT id FROM wms.item_category WHERE name = 'MC1'), (SELECT id FROM wms.item_brand WHERE brand_name = 'MB1'), (SELECT id FROM wms.hsn WHERE hsn_code = 'HSN4'),  1),
('MAT-005', 'Material 005', (SELECT id FROM wms.item_category WHERE name = 'MC1'), (SELECT id FROM wms.item_brand WHERE brand_name = 'MB1'), (SELECT id FROM wms.hsn WHERE hsn_code = 'HSN5'),  1),
('MAT-006', 'Material 006', (SELECT id FROM wms.item_category WHERE name = 'MC1'), (SELECT id FROM wms.item_brand WHERE brand_name = 'MB1'), (SELECT id FROM wms.hsn WHERE hsn_code = 'HSN6'),  1),
('MAT-007', 'Material 007', (SELECT id FROM wms.item_category WHERE name = 'MC1'), (SELECT id FROM wms.item_brand WHERE brand_name = 'MB1'), (SELECT id FROM wms.hsn WHERE hsn_code = 'HSN7'),  1),
('MAT-008', 'Material 008', (SELECT id FROM wms.item_category WHERE name = 'MC1'), (SELECT id FROM wms.item_brand WHERE brand_name = 'MB1'), (SELECT id FROM wms.hsn WHERE hsn_code = 'HSN8'),  1),
('MAT-009', 'Material 009', (SELECT id FROM wms.item_category WHERE name = 'MC1'), (SELECT id FROM wms.item_brand WHERE brand_name = 'MB1'), (SELECT id FROM wms.hsn WHERE hsn_code = 'HSN9'),  1),
('MAT-010', 'Material 010', (SELECT id FROM wms.item_category WHERE name = 'MC1'), (SELECT id FROM wms.item_brand WHERE brand_name = 'MB1'), (SELECT id FROM wms.hsn WHERE hsn_code = 'HSN10'), 1);

INSERT INTO wms.material_ean (material_id, ean_code, label, uom_pc_id, uom_package_id, mrp, selling_rate, lub) VALUES
-- MAT-001 (MRP ~200)
((SELECT id FROM wms.material WHERE name = 'MAT-001'), 'M01-E01', 'MAT-001 Variant A', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 200.00, 180.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-001'), 'M01-E02', 'MAT-001 Variant B', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 210.00, 190.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-001'), 'M01-E03', 'MAT-001 Variant C', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 215.00, 195.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-001'), 'M01-E04', 'MAT-001 Variant D', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 220.00, 198.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-001'), 'M01-E05', 'MAT-001 Variant E', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 225.00, 200.00, 1),
-- MAT-002 (MRP ~350)
((SELECT id FROM wms.material WHERE name = 'MAT-002'), 'M02-E01', 'MAT-002 Variant A', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 350.00, 310.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-002'), 'M02-E02', 'MAT-002 Variant B', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 360.00, 320.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-002'), 'M02-E03', 'MAT-002 Variant C', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 370.00, 335.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-002'), 'M02-E04', 'MAT-002 Variant D', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 375.00, 340.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-002'), 'M02-E05', 'MAT-002 Variant E', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 380.00, 350.00, 1),
-- MAT-003 (MRP ~500)
((SELECT id FROM wms.material WHERE name = 'MAT-003'), 'M03-E01', 'MAT-003 Variant A', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 500.00, 450.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-003'), 'M03-E02', 'MAT-003 Variant B', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 510.00, 460.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-003'), 'M03-E03', 'MAT-003 Variant C', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 520.00, 475.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-003'), 'M03-E04', 'MAT-003 Variant D', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 525.00, 480.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-003'), 'M03-E05', 'MAT-003 Variant E', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 530.00, 490.00, 1),
-- MAT-004 (MRP ~150)
((SELECT id FROM wms.material WHERE name = 'MAT-004'), 'M04-E01', 'MAT-004 Variant A', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 150.00, 130.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-004'), 'M04-E02', 'MAT-004 Variant B', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 155.00, 135.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-004'), 'M04-E03', 'MAT-004 Variant C', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 160.00, 142.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-004'), 'M04-E04', 'MAT-004 Variant D', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 165.00, 148.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-004'), 'M04-E05', 'MAT-004 Variant E', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 170.00, 155.00, 1),
-- MAT-005 (MRP ~600)
((SELECT id FROM wms.material WHERE name = 'MAT-005'), 'M05-E01', 'MAT-005 Variant A', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 600.00, 545.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-005'), 'M05-E02', 'MAT-005 Variant B', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 615.00, 560.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-005'), 'M05-E03', 'MAT-005 Variant C', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 620.00, 570.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-005'), 'M05-E04', 'MAT-005 Variant D', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 630.00, 580.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-005'), 'M05-E05', 'MAT-005 Variant E', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 640.00, 595.00, 1),
-- MAT-006 (MRP ~280)
((SELECT id FROM wms.material WHERE name = 'MAT-006'), 'M06-E01', 'MAT-006 Variant A', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 280.00, 250.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-006'), 'M06-E02', 'MAT-006 Variant B', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 285.00, 255.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-006'), 'M06-E03', 'MAT-006 Variant C', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 290.00, 262.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-006'), 'M06-E04', 'MAT-006 Variant D', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 295.00, 268.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-006'), 'M06-E05', 'MAT-006 Variant E', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 300.00, 275.00, 1),
-- MAT-007 (MRP ~420)
((SELECT id FROM wms.material WHERE name = 'MAT-007'), 'M07-E01', 'MAT-007 Variant A', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 420.00, 380.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-007'), 'M07-E02', 'MAT-007 Variant B', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 430.00, 390.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-007'), 'M07-E03', 'MAT-007 Variant C', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 435.00, 398.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-007'), 'M07-E04', 'MAT-007 Variant D', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 440.00, 405.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-007'), 'M07-E05', 'MAT-007 Variant E', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 450.00, 415.00, 1),
-- MAT-008 (MRP ~750)
((SELECT id FROM wms.material WHERE name = 'MAT-008'), 'M08-E01', 'MAT-008 Variant A', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 750.00, 680.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-008'), 'M08-E02', 'MAT-008 Variant B', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 760.00, 695.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-008'), 'M08-E03', 'MAT-008 Variant C', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 775.00, 710.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-008'), 'M08-E04', 'MAT-008 Variant D', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 780.00, 720.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-008'), 'M08-E05', 'MAT-008 Variant E', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 790.00, 740.00, 1),
-- MAT-009 (MRP ~120)
((SELECT id FROM wms.material WHERE name = 'MAT-009'), 'M09-E01', 'MAT-009 Variant A', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 120.00, 105.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-009'), 'M09-E02', 'MAT-009 Variant B', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 125.00, 110.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-009'), 'M09-E03', 'MAT-009 Variant C', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 128.00, 115.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-009'), 'M09-E04', 'MAT-009 Variant D', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 130.00, 118.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-009'), 'M09-E05', 'MAT-009 Variant E', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 135.00, 122.00, 1),
-- MAT-010 (MRP ~900)
((SELECT id FROM wms.material WHERE name = 'MAT-010'), 'M10-E01', 'MAT-010 Variant A', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 900.00, 820.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-010'), 'M10-E02', 'MAT-010 Variant B', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 910.00, 835.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-010'), 'M10-E03', 'MAT-010 Variant C', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 920.00, 850.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-010'), 'M10-E04', 'MAT-010 Variant D', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 935.00, 865.00, 1),
((SELECT id FROM wms.material WHERE name = 'MAT-010'), 'M10-E05', 'MAT-010 Variant E', (SELECT id FROM wms.uom WHERE name = 'PCS'), (SELECT id FROM wms.uom WHERE name = 'BOX24'), 950.00, 880.00, 1);

-- Addresses, Vendors, Parties, and Purchase Orders via insert functions
DO $$
DECLARE
    v_city_id     INTEGER;
    v_district_id INTEGER;
    v_state_id    INTEGER;
    v_country_id  INTEGER;
    v_uom_pcs_id  INTEGER;
    v_uom_box_id  INTEGER;
    v_vc1_id      INTEGER;
    v_pc1_id      INTEGER;

    v_add1_id INTEGER;
    v_add2_id INTEGER;
    v_add3_id INTEGER;
    v_add4_id INTEGER;

    v_v1_id INTEGER;
    v_v2_id INTEGER;
    v_p1_id INTEGER;
    v_p2_id INTEGER;

    v_po1_id INTEGER;
    v_po2_id INTEGER;
    v_po3_id INTEGER;
    v_po4_id INTEGER;

    -- material IDs
    v_mat001_id INTEGER; v_mat002_id INTEGER; v_mat003_id INTEGER;
    v_mat004_id INTEGER; v_mat005_id INTEGER;
    v_mat006_id INTEGER; v_mat007_id INTEGER; v_mat008_id INTEGER;
    v_mat009_id INTEGER; v_mat010_id INTEGER;
BEGIN
    -- Resolve shared lookup IDs
    SELECT id INTO v_city_id     FROM wms.city     WHERE code = 'GGN';
    SELECT id INTO v_district_id FROM wms.district WHERE code = 'GGN';
    SELECT id INTO v_state_id    FROM wms.state    WHERE name = 'Haryana';
    SELECT id INTO v_country_id  FROM wms.country  WHERE code = 'IN';
    SELECT id INTO v_uom_pcs_id  FROM wms.uom      WHERE name = 'PCS';
    SELECT id INTO v_uom_box_id  FROM wms.uom      WHERE name = 'BOX24';
    SELECT id INTO v_vc1_id      FROM wms.vendor_category WHERE name = 'VC1';
    SELECT id INTO v_pc1_id      FROM wms.party_category  WHERE name = 'PC1';

    -- Resolve material IDs
    SELECT id INTO v_mat001_id FROM wms.material WHERE name = 'MAT-001';
    SELECT id INTO v_mat002_id FROM wms.material WHERE name = 'MAT-002';
    SELECT id INTO v_mat003_id FROM wms.material WHERE name = 'MAT-003';
    SELECT id INTO v_mat004_id FROM wms.material WHERE name = 'MAT-004';
    SELECT id INTO v_mat005_id FROM wms.material WHERE name = 'MAT-005';
    SELECT id INTO v_mat006_id FROM wms.material WHERE name = 'MAT-006';
    SELECT id INTO v_mat007_id FROM wms.material WHERE name = 'MAT-007';
    SELECT id INTO v_mat008_id FROM wms.material WHERE name = 'MAT-008';
    SELECT id INTO v_mat009_id FROM wms.material WHERE name = 'MAT-009';
    SELECT id INTO v_mat010_id FROM wms.material WHERE name = 'MAT-010';

    -- Create 4 addresses
    v_add1_id := wms.insert_address('Plot 1, Sector 18', 'Industrial Area, Phase I',  NULL, v_city_id, v_district_id, v_state_id, v_country_id, 1);
    v_add2_id := wms.insert_address('Plot 2, Sector 29', 'Industrial Area, Phase II', NULL, v_city_id, v_district_id, v_state_id, v_country_id, 1);
    v_add3_id := wms.insert_address('Plot 3, Sector 44', 'Industrial Area, Phase III', NULL, v_city_id, v_district_id, v_state_id, v_country_id, 1);
    v_add4_id := wms.insert_address('Plot 4, Sector 56', 'Industrial Area, Phase IV',  NULL, v_city_id, v_district_id, v_state_id, v_country_id, 1);

    -- Create 2 vendors (V1 → delivery add1, V2 → delivery add2)
    v_v1_id := wms.insert_vendor(
        v_vc1_id, 'TRADER', 'V1',
        'Plot 1, Sector 18', 'Industrial Area, Phase I', NULL,
        v_city_id, v_district_id, v_state_id, v_country_id,
        '122015', NULL, 'ABCDE1234F', 0, 0, 'GST06ABCDE1234F1Z5', NULL, 1
    );
    v_v2_id := wms.insert_vendor(
        v_vc1_id, 'TRADER', 'V2',
        'Plot 2, Sector 29', 'Industrial Area, Phase II', NULL,
        v_city_id, v_district_id, v_state_id, v_country_id,
        '122017', NULL, 'FGHIJ5678K', 0, 0, 'GST06FGHIJ5678K2Z8', NULL, 1
    );

    -- Create 2 parties (P1 → delivery add1, P2 → delivery add2)
    v_p1_id := wms.insert_party(
        v_pc1_id, 'RETAILER', 'P1',
        'Plot 1, Sector 18', 'Industrial Area, Phase I', NULL,
        v_city_id, v_district_id, v_state_id, v_country_id,
        '122001', NULL, 'XYZAB5678G', 0, 0, 'GST06XYZAB5678G1Z3', NULL, 1
    );
    v_p2_id := wms.insert_party(
        v_pc1_id, 'RETAILER', 'P2',
        'Plot 2, Sector 29', 'Industrial Area, Phase II', NULL,
        v_city_id, v_district_id, v_state_id, v_country_id,
        '122003', NULL, 'PQRST9012H', 0, 0, 'GST06PQRST9012H3Z1', NULL, 1
    );

    -- PO1: V1, delivery at add1, MAT-001..005
    SELECT id INTO v_po1_id FROM wms.insert_purchase_order_header(
        NOW()::TIMESTAMP, v_v1_id, NULL::INTEGER, v_add1_id, NULL::INTEGER, (NOW() + INTERVAL '15 days')::TIMESTAMP, 0, 'Initial PO - V1 batch 1'::VARCHAR, 1
    );
    PERFORM wms.insert_purchase_order_details(v_po1_id, v_mat001_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 180.00, 1200, 50, 216000.00, NULL::VARCHAR, 1);
    PERFORM wms.insert_purchase_order_details(v_po1_id, v_mat002_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 310.00, 1200, 50, 372000.00, NULL::VARCHAR, 1);
    PERFORM wms.insert_purchase_order_details(v_po1_id, v_mat003_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 450.00, 1200, 50, 540000.00, NULL::VARCHAR, 1);
    PERFORM wms.insert_purchase_order_details(v_po1_id, v_mat004_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 130.00, 1200, 50, 156000.00, NULL::VARCHAR, 1);
    PERFORM wms.insert_purchase_order_details(v_po1_id, v_mat005_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 545.00, 1200, 50, 654000.00, NULL::VARCHAR, 1);

    -- PO2: V1, delivery at add1, MAT-006..010
    SELECT id INTO v_po2_id FROM wms.insert_purchase_order_header(
        NOW()::TIMESTAMP, v_v1_id, NULL::INTEGER, v_add1_id, NULL::INTEGER, (NOW() + INTERVAL '20 days')::TIMESTAMP, 0, 'Initial PO - V1 batch 2'::VARCHAR, 1
    );
    PERFORM wms.insert_purchase_order_details(v_po2_id, v_mat006_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 250.00, 1200, 50, 300000.00, NULL::VARCHAR, 1);
    PERFORM wms.insert_purchase_order_details(v_po2_id, v_mat007_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 380.00, 1200, 50, 456000.00, NULL::VARCHAR, 1);
    PERFORM wms.insert_purchase_order_details(v_po2_id, v_mat008_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 680.00, 1200, 50, 816000.00, NULL::VARCHAR, 1);
    PERFORM wms.insert_purchase_order_details(v_po2_id, v_mat009_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 105.00, 1200, 50, 126000.00, NULL::VARCHAR, 1);
    PERFORM wms.insert_purchase_order_details(v_po2_id, v_mat010_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 820.00, 1200, 50, 984000.00, NULL::VARCHAR, 1);

    -- PO3: V2, delivery at add2, MAT-001..005
    SELECT id INTO v_po3_id FROM wms.insert_purchase_order_header(
        NOW()::TIMESTAMP, v_v2_id, NULL::INTEGER, v_add2_id, NULL::INTEGER, (NOW() + INTERVAL '15 days')::TIMESTAMP, 0, 'Initial PO - V2 batch 1'::VARCHAR, 1
    );
    PERFORM wms.insert_purchase_order_details(v_po3_id, v_mat001_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 180.00, 1200, 50, 216000.00, NULL::VARCHAR, 1);
    PERFORM wms.insert_purchase_order_details(v_po3_id, v_mat002_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 310.00, 1200, 50, 372000.00, NULL::VARCHAR, 1);
    PERFORM wms.insert_purchase_order_details(v_po3_id, v_mat003_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 450.00, 1200, 50, 540000.00, NULL::VARCHAR, 1);
    PERFORM wms.insert_purchase_order_details(v_po3_id, v_mat004_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 130.00, 1200, 50, 156000.00, NULL::VARCHAR, 1);
    PERFORM wms.insert_purchase_order_details(v_po3_id, v_mat005_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 545.00, 1200, 50, 654000.00, NULL::VARCHAR, 1);

    -- PO4: V2, delivery at add2, MAT-006..010
    SELECT id INTO v_po4_id FROM wms.insert_purchase_order_header(
        NOW()::TIMESTAMP, v_v2_id, NULL::INTEGER, v_add2_id, NULL::INTEGER, (NOW() + INTERVAL '20 days')::TIMESTAMP, 0, 'Initial PO - V2 batch 2'::VARCHAR, 1
    );
    PERFORM wms.insert_purchase_order_details(v_po4_id, v_mat006_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 250.00, 1200, 50, 300000.00, NULL::VARCHAR, 1);
    PERFORM wms.insert_purchase_order_details(v_po4_id, v_mat007_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 380.00, 1200, 50, 456000.00, NULL::VARCHAR, 1);
    PERFORM wms.insert_purchase_order_details(v_po4_id, v_mat008_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 680.00, 1200, 50, 816000.00, NULL::VARCHAR, 1);
    PERFORM wms.insert_purchase_order_details(v_po4_id, v_mat009_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 105.00, 1200, 50, 126000.00, NULL::VARCHAR, 1);
    PERFORM wms.insert_purchase_order_details(v_po4_id, v_mat010_id, v_uom_pcs_id, v_uom_box_id, v_uom_box_id, 820.00, 1200, 50, 984000.00, NULL::VARCHAR, 1);

END $$;

-- Transport
INSERT INTO wms.transport (name, descr, lub) VALUES
('TRN-001', 'Default Transport', 1);

-- Sales Orders: SO1..SO3 across P1 and P2
DO $$
DECLARE
    v_uom_pcs_id  INTEGER;
    v_uom_box_id  INTEGER;
    v_p1_id       INTEGER;
    v_p2_id       INTEGER;
    v_add1_id     INTEGER;
    v_add2_id     INTEGER;
    v_trsp_id     INTEGER;
    v_mat001_id   INTEGER; v_mat002_id INTEGER; v_mat003_id INTEGER;
    v_mat004_id   INTEGER; v_mat005_id INTEGER;
    v_mat006_id   INTEGER; v_mat007_id INTEGER; v_mat008_id INTEGER;
    v_mat009_id   INTEGER; v_mat010_id INTEGER;
    v_so1_id      INTEGER;
    v_so2_id      INTEGER;
    v_so3_id      INTEGER;
BEGIN
    SELECT id INTO v_uom_pcs_id FROM wms.uom WHERE name = 'PCS';
    SELECT id INTO v_uom_box_id FROM wms.uom WHERE name = 'BOX24';
    SELECT id INTO v_p1_id      FROM wms.party WHERE name = 'P1';
    SELECT id INTO v_p2_id      FROM wms.party WHERE name = 'P2';
    SELECT id INTO v_trsp_id    FROM wms.transport WHERE name = 'TRN-001' LIMIT 1;
    SELECT id INTO v_add1_id    FROM wms.address WHERE adr1 = 'Plot 1, Sector 18' LIMIT 1;
    SELECT id INTO v_add2_id    FROM wms.address WHERE adr1 = 'Plot 2, Sector 29' LIMIT 1;

    SELECT id INTO v_mat001_id FROM wms.material WHERE name = 'MAT-001';
    SELECT id INTO v_mat002_id FROM wms.material WHERE name = 'MAT-002';
    SELECT id INTO v_mat003_id FROM wms.material WHERE name = 'MAT-003';
    SELECT id INTO v_mat004_id FROM wms.material WHERE name = 'MAT-004';
    SELECT id INTO v_mat005_id FROM wms.material WHERE name = 'MAT-005';
    SELECT id INTO v_mat006_id FROM wms.material WHERE name = 'MAT-006';
    SELECT id INTO v_mat007_id FROM wms.material WHERE name = 'MAT-007';
    SELECT id INTO v_mat008_id FROM wms.material WHERE name = 'MAT-008';
    SELECT id INTO v_mat009_id FROM wms.material WHERE name = 'MAT-009';
    SELECT id INTO v_mat010_id FROM wms.material WHERE name = 'MAT-010';

    -- SO1: P1 — MAT-001, MAT-002, MAT-003 (300 pcs each)
    -- args: entry_dt, party_id, broker_id, delivery_at_id, trsp_id, delivery_dt, status, remarks, current_user_id
    SELECT id INTO v_so1_id FROM wms.insert_sales_order_header(
        NOW()::TIMESTAMP, v_p1_id, NULL::INTEGER, v_add1_id, v_trsp_id,
        (NOW() + INTERVAL '7 days')::TIMESTAMP, 0, 'SO1 - P1 batch 1', 1
    );
    -- args: header_id, item_id, euom, puom, quom, rate_per_pc, eqty, pqty, amount, dqty, remarks, current_user_id
    PERFORM wms.insert_sales_order_details(v_so1_id, v_mat001_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 180.00, 300, 0, 54000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so1_id, v_mat002_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 310.00, 300, 0, 93000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so1_id, v_mat003_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 450.00, 300, 0, 135000.00, 0, NULL::VARCHAR, 1);

    -- SO2: P1 — MAT-004, MAT-005, MAT-006, MAT-007 (200 pcs each)
    SELECT id INTO v_so2_id FROM wms.insert_sales_order_header(
        NOW()::TIMESTAMP, v_p1_id, NULL::INTEGER, v_add1_id, v_trsp_id,
        (NOW() + INTERVAL '10 days')::TIMESTAMP, 0, 'SO2 - P1 batch 2', 1
    );
    PERFORM wms.insert_sales_order_details(v_so2_id, v_mat004_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 130.00, 200, 0, 26000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so2_id, v_mat005_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 545.00, 200, 0, 109000.00, 0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so2_id, v_mat006_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 250.00, 200, 0, 50000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so2_id, v_mat007_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 380.00, 200, 0, 76000.00,  0, NULL::VARCHAR, 1);

    -- SO3: P2 — MAT-008, MAT-009, MAT-010 (150 pcs each)
    SELECT id INTO v_so3_id FROM wms.insert_sales_order_header(
        NOW()::TIMESTAMP, v_p2_id, NULL::INTEGER, v_add2_id, v_trsp_id,
        (NOW() + INTERVAL '14 days')::TIMESTAMP, 0, 'SO3 - P2 batch 1', 1
    );
    PERFORM wms.insert_sales_order_details(v_so3_id, v_mat008_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 680.00, 150, 0, 102000.00, 0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so3_id, v_mat009_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 105.00, 150, 0, 15750.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so3_id, v_mat010_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 820.00, 150, 0, 123000.00, 0, NULL::VARCHAR, 1);
END $$;

-- Sales Orders SO4..SO13 — varied material mixes across P1 and P2
DO $$
DECLARE
    v_uom_pcs_id  INTEGER;
    v_uom_box_id  INTEGER;
    v_p1_id       INTEGER;
    v_p2_id       INTEGER;
    v_add1_id     INTEGER;
    v_add2_id     INTEGER;
    v_trsp_id     INTEGER;
    v_mat001_id   INTEGER; v_mat002_id INTEGER; v_mat003_id INTEGER;
    v_mat004_id   INTEGER; v_mat005_id INTEGER;
    v_mat006_id   INTEGER; v_mat007_id INTEGER; v_mat008_id INTEGER;
    v_mat009_id   INTEGER; v_mat010_id INTEGER;
    v_so_id       INTEGER;
BEGIN
    SELECT id INTO v_uom_pcs_id FROM wms.uom WHERE name = 'PCS';
    SELECT id INTO v_uom_box_id FROM wms.uom WHERE name = 'BOX24';
    SELECT id INTO v_p1_id      FROM wms.party WHERE name = 'P1';
    SELECT id INTO v_p2_id      FROM wms.party WHERE name = 'P2';
    SELECT id INTO v_trsp_id    FROM wms.transport WHERE name = 'TRN-001' LIMIT 1;
    SELECT id INTO v_add1_id    FROM wms.address WHERE adr1 = 'Plot 1, Sector 18' LIMIT 1;
    SELECT id INTO v_add2_id    FROM wms.address WHERE adr1 = 'Plot 2, Sector 29' LIMIT 1;

    SELECT id INTO v_mat001_id FROM wms.material WHERE name = 'MAT-001';
    SELECT id INTO v_mat002_id FROM wms.material WHERE name = 'MAT-002';
    SELECT id INTO v_mat003_id FROM wms.material WHERE name = 'MAT-003';
    SELECT id INTO v_mat004_id FROM wms.material WHERE name = 'MAT-004';
    SELECT id INTO v_mat005_id FROM wms.material WHERE name = 'MAT-005';
    SELECT id INTO v_mat006_id FROM wms.material WHERE name = 'MAT-006';
    SELECT id INTO v_mat007_id FROM wms.material WHERE name = 'MAT-007';
    SELECT id INTO v_mat008_id FROM wms.material WHERE name = 'MAT-008';
    SELECT id INTO v_mat009_id FROM wms.material WHERE name = 'MAT-009';
    SELECT id INTO v_mat010_id FROM wms.material WHERE name = 'MAT-010';

    -- SO4: P1 — MAT-001,002,005,007,009 (100 pcs each)
    SELECT id INTO v_so_id FROM wms.insert_sales_order_header(
        NOW()::TIMESTAMP, v_p1_id, NULL::INTEGER, v_add1_id, v_trsp_id,
        (NOW() + INTERVAL '5 days')::TIMESTAMP, 0, 'SO4 - P1 mixed batch 1', 1
    );
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat001_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 180.00, 100, 0, 18000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat002_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 310.00, 100, 0, 31000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat005_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 545.00, 100, 0, 54500.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat007_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 380.00, 100, 0, 38000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat009_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 105.00, 100, 0, 10500.00,  0, NULL::VARCHAR, 1);

    -- SO5: P2 — MAT-002,003,004,006,008 (150 pcs each)
    SELECT id INTO v_so_id FROM wms.insert_sales_order_header(
        NOW()::TIMESTAMP, v_p2_id, NULL::INTEGER, v_add2_id, v_trsp_id,
        (NOW() + INTERVAL '6 days')::TIMESTAMP, 0, 'SO5 - P2 mixed batch 1', 1
    );
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat002_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 310.00, 150, 0, 46500.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat003_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 450.00, 150, 0, 67500.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat004_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 130.00, 150, 0, 19500.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat006_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 250.00, 150, 0, 37500.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat008_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 680.00, 150, 0, 102000.00, 0, NULL::VARCHAR, 1);

    -- SO6: P1 — MAT-001,003,005,007,009 (80 pcs each)
    SELECT id INTO v_so_id FROM wms.insert_sales_order_header(
        NOW()::TIMESTAMP, v_p1_id, NULL::INTEGER, v_add1_id, v_trsp_id,
        (NOW() + INTERVAL '8 days')::TIMESTAMP, 0, 'SO6 - P1 odd batch 1', 1
    );
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat001_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 180.00,  80, 0, 14400.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat003_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 450.00,  80, 0, 36000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat005_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 545.00,  80, 0, 43600.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat007_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 380.00,  80, 0, 30400.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat009_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 105.00,  80, 0,  8400.00,  0, NULL::VARCHAR, 1);

    -- SO7: P2 — MAT-002,004,006,008,010 (200 pcs each)
    SELECT id INTO v_so_id FROM wms.insert_sales_order_header(
        NOW()::TIMESTAMP, v_p2_id, NULL::INTEGER, v_add2_id, v_trsp_id,
        (NOW() + INTERVAL '9 days')::TIMESTAMP, 0, 'SO7 - P2 even batch 1', 1
    );
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat002_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 310.00, 200, 0, 62000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat004_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 130.00, 200, 0, 26000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat006_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 250.00, 200, 0, 50000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat008_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 680.00, 200, 0, 136000.00, 0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat010_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 820.00, 200, 0, 164000.00, 0, NULL::VARCHAR, 1);

    -- SO8: P1 — MAT-003,004,005,006,007,008 (120 pcs each)
    SELECT id INTO v_so_id FROM wms.insert_sales_order_header(
        NOW()::TIMESTAMP, v_p1_id, NULL::INTEGER, v_add1_id, v_trsp_id,
        (NOW() + INTERVAL '11 days')::TIMESTAMP, 0, 'SO8 - P1 mid batch 1', 1
    );
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat003_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 450.00, 120, 0, 54000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat004_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 130.00, 120, 0, 15600.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat005_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 545.00, 120, 0, 65400.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat006_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 250.00, 120, 0, 30000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat007_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 380.00, 120, 0, 45600.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat008_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 680.00, 120, 0, 81600.00,  0, NULL::VARCHAR, 1);

    -- SO9: P2 — MAT-001,002,003,007,010 (90 pcs each)
    SELECT id INTO v_so_id FROM wms.insert_sales_order_header(
        NOW()::TIMESTAMP, v_p2_id, NULL::INTEGER, v_add2_id, v_trsp_id,
        (NOW() + INTERVAL '12 days')::TIMESTAMP, 0, 'SO9 - P2 mixed batch 2', 1
    );
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat001_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 180.00,  90, 0, 16200.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat002_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 310.00,  90, 0, 27900.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat003_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 450.00,  90, 0, 40500.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat007_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 380.00,  90, 0, 34200.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat010_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 820.00,  90, 0, 73800.00,  0, NULL::VARCHAR, 1);

    -- SO10: P1 — MAT-004,005,006,009,010 (250 pcs each)
    SELECT id INTO v_so_id FROM wms.insert_sales_order_header(
        NOW()::TIMESTAMP, v_p1_id, NULL::INTEGER, v_add1_id, v_trsp_id,
        (NOW() + INTERVAL '13 days')::TIMESTAMP, 0, 'SO10 - P1 high-vol batch 1', 1
    );
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat004_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 130.00, 250, 0, 32500.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat005_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 545.00, 250, 0, 136250.00, 0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat006_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 250.00, 250, 0, 62500.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat009_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 105.00, 250, 0, 26250.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat010_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 820.00, 250, 0, 205000.00, 0, NULL::VARCHAR, 1);

    -- SO11: P2 — MAT-001,003,005,007,009 (180 pcs each)
    SELECT id INTO v_so_id FROM wms.insert_sales_order_header(
        NOW()::TIMESTAMP, v_p2_id, NULL::INTEGER, v_add2_id, v_trsp_id,
        (NOW() + INTERVAL '15 days')::TIMESTAMP, 0, 'SO11 - P2 odd batch 2', 1
    );
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat001_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 180.00, 180, 0, 32400.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat003_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 450.00, 180, 0, 81000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat005_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 545.00, 180, 0, 98100.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat007_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 380.00, 180, 0, 68400.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat009_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 105.00, 180, 0, 18900.00,  0, NULL::VARCHAR, 1);

    -- SO12: P1 — MAT-002,004,006,008,010 (75 pcs each)
    SELECT id INTO v_so_id FROM wms.insert_sales_order_header(
        NOW()::TIMESTAMP, v_p1_id, NULL::INTEGER, v_add1_id, v_trsp_id,
        (NOW() + INTERVAL '17 days')::TIMESTAMP, 0, 'SO12 - P1 even batch 2', 1
    );
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat002_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 310.00,  75, 0, 23250.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat004_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 130.00,  75, 0,  9750.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat006_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 250.00,  75, 0, 18750.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat008_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 680.00,  75, 0, 51000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat010_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 820.00,  75, 0, 61500.00,  0, NULL::VARCHAR, 1);

    -- SO13: P2 — MAT-001,002,004,006,008,010 (100 pcs each)
    SELECT id INTO v_so_id FROM wms.insert_sales_order_header(
        NOW()::TIMESTAMP, v_p2_id, NULL::INTEGER, v_add2_id, v_trsp_id,
        (NOW() + INTERVAL '20 days')::TIMESTAMP, 0, 'SO13 - P2 mixed batch 3', 1
    );
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat001_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 180.00, 100, 0, 18000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat002_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 310.00, 100, 0, 31000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat004_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 130.00, 100, 0, 13000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat006_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 250.00, 100, 0, 25000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat008_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 680.00, 100, 0, 68000.00,  0, NULL::VARCHAR, 1);
    PERFORM wms.insert_sales_order_details(v_so_id, v_mat010_id, v_uom_pcs_id, v_uom_box_id, v_uom_pcs_id, 820.00, 100, 0, 82000.00,  0, NULL::VARCHAR, 1);
END $$;

-- Draft inward for PO1 (V1, MAT-001..005) — process manually from the dashboard to stock up
DO $$
DECLARE
    v_v1_id       INTEGER;
    v_po1_id      INTEGER;
    v_inward_id   INTEGER;
    v_uom_pcs_id  INTEGER;
    v_uom_box_id  INTEGER;
    v_ean_m01     INTEGER;
    v_ean_m02     INTEGER;
    v_ean_m03     INTEGER;
    v_ean_m04     INTEGER;
    v_ean_m05     INTEGER;
    v_pod1_id     INTEGER;
    v_pod2_id     INTEGER;
    v_pod3_id     INTEGER;
    v_pod4_id     INTEGER;
    v_pod5_id     INTEGER;
BEGIN
    SELECT id INTO v_v1_id      FROM wms.vendor WHERE name = 'V1';
    SELECT id INTO v_uom_pcs_id FROM wms.uom    WHERE name = 'PCS';
    SELECT id INTO v_uom_box_id FROM wms.uom    WHERE name = 'BOX24';

    -- First PO for V1
    SELECT id INTO v_po1_id FROM wms.purchase_order_header
    WHERE vendor_id = v_v1_id ORDER BY id LIMIT 1;

    -- First EAN per material
    SELECT me.id INTO v_ean_m01 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-001' ORDER BY me.id LIMIT 1;
    SELECT me.id INTO v_ean_m02 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-002' ORDER BY me.id LIMIT 1;
    SELECT me.id INTO v_ean_m03 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-003' ORDER BY me.id LIMIT 1;
    SELECT me.id INTO v_ean_m04 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-004' ORDER BY me.id LIMIT 1;
    SELECT me.id INTO v_ean_m05 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-005' ORDER BY me.id LIMIT 1;

    -- PO detail rows (ordered by insertion = row_no order)
    SELECT id INTO v_pod1_id FROM wms.purchase_order_details WHERE header_id = v_po1_id ORDER BY id LIMIT 1 OFFSET 0;
    SELECT id INTO v_pod2_id FROM wms.purchase_order_details WHERE header_id = v_po1_id ORDER BY id LIMIT 1 OFFSET 1;
    SELECT id INTO v_pod3_id FROM wms.purchase_order_details WHERE header_id = v_po1_id ORDER BY id LIMIT 1 OFFSET 2;
    SELECT id INTO v_pod4_id FROM wms.purchase_order_details WHERE header_id = v_po1_id ORDER BY id LIMIT 1 OFFSET 3;
    SELECT id INTO v_pod5_id FROM wms.purchase_order_details WHERE header_id = v_po1_id ORDER BY id LIMIT 1 OFFSET 4;

    -- Create Draft inward header
    SELECT id INTO v_inward_id FROM wms.insert_inward_header(
        CURRENT_DATE,
        v_v1_id,
        v_po1_id::TEXT,
        NULL,   -- invoice_no
        NULL,   -- invoice_dt
        0,      -- Draft
        'Initial seed inward for PO1 — process to load stock',
        1
    );

    -- Inward details: full ordered qty for each item (expiry 6 months out)
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m01, v_pod1_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 180.00, 216000.00, (CURRENT_DATE + INTERVAL '6 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m02, v_pod2_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 310.00, 372000.00, (CURRENT_DATE + INTERVAL '6 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m03, v_pod3_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 450.00, 540000.00, (CURRENT_DATE + INTERVAL '6 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m04, v_pod4_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 130.00, 156000.00, (CURRENT_DATE + INTERVAL '6 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m05, v_pod5_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 545.00, 654000.00, (CURRENT_DATE + INTERVAL '6 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
END $$;

-- Draft inward for PO2 (V1, MAT-006..010)
DO $$
DECLARE
    v_v1_id       INTEGER;
    v_po2_id      INTEGER;
    v_inward_id   INTEGER;
    v_uom_pcs_id  INTEGER;
    v_uom_box_id  INTEGER;
    v_ean_m06     INTEGER; v_ean_m07 INTEGER; v_ean_m08 INTEGER;
    v_ean_m09     INTEGER; v_ean_m10 INTEGER;
    v_pod1_id     INTEGER; v_pod2_id INTEGER; v_pod3_id INTEGER;
    v_pod4_id     INTEGER; v_pod5_id INTEGER;
BEGIN
    SELECT id INTO v_v1_id      FROM wms.vendor WHERE name = 'V1';
    SELECT id INTO v_uom_pcs_id FROM wms.uom    WHERE name = 'PCS';
    SELECT id INTO v_uom_box_id FROM wms.uom    WHERE name = 'BOX24';

    -- Second PO for V1
    SELECT id INTO v_po2_id FROM wms.purchase_order_header
    WHERE vendor_id = v_v1_id ORDER BY id LIMIT 1 OFFSET 1;

    SELECT me.id INTO v_ean_m06 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-006' ORDER BY me.id LIMIT 1;
    SELECT me.id INTO v_ean_m07 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-007' ORDER BY me.id LIMIT 1;
    SELECT me.id INTO v_ean_m08 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-008' ORDER BY me.id LIMIT 1;
    SELECT me.id INTO v_ean_m09 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-009' ORDER BY me.id LIMIT 1;
    SELECT me.id INTO v_ean_m10 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-010' ORDER BY me.id LIMIT 1;

    SELECT id INTO v_pod1_id FROM wms.purchase_order_details WHERE header_id = v_po2_id ORDER BY id LIMIT 1 OFFSET 0;
    SELECT id INTO v_pod2_id FROM wms.purchase_order_details WHERE header_id = v_po2_id ORDER BY id LIMIT 1 OFFSET 1;
    SELECT id INTO v_pod3_id FROM wms.purchase_order_details WHERE header_id = v_po2_id ORDER BY id LIMIT 1 OFFSET 2;
    SELECT id INTO v_pod4_id FROM wms.purchase_order_details WHERE header_id = v_po2_id ORDER BY id LIMIT 1 OFFSET 3;
    SELECT id INTO v_pod5_id FROM wms.purchase_order_details WHERE header_id = v_po2_id ORDER BY id LIMIT 1 OFFSET 4;

    SELECT id INTO v_inward_id FROM wms.insert_inward_header(
        CURRENT_DATE, v_v1_id, v_po2_id::TEXT, NULL, NULL, 0,
        'Inward for PO2 — V1 MAT-006..010', 1
    );
    -- expiry 9 months out
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m06, v_pod1_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 250.00, 300000.00, (CURRENT_DATE + INTERVAL '9 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m07, v_pod2_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 380.00, 456000.00, (CURRENT_DATE + INTERVAL '9 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m08, v_pod3_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 680.00, 816000.00, (CURRENT_DATE + INTERVAL '9 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m09, v_pod4_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 105.00, 126000.00, (CURRENT_DATE + INTERVAL '9 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m10, v_pod5_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 820.00, 984000.00, (CURRENT_DATE + INTERVAL '9 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
END $$;

-- Draft inward for PO3 (V2, MAT-001..005)
DO $$
DECLARE
    v_v2_id       INTEGER;
    v_po3_id      INTEGER;
    v_inward_id   INTEGER;
    v_uom_pcs_id  INTEGER;
    v_uom_box_id  INTEGER;
    v_ean_m01     INTEGER; v_ean_m02 INTEGER; v_ean_m03 INTEGER;
    v_ean_m04     INTEGER; v_ean_m05 INTEGER;
    v_pod1_id     INTEGER; v_pod2_id INTEGER; v_pod3_id INTEGER;
    v_pod4_id     INTEGER; v_pod5_id INTEGER;
BEGIN
    SELECT id INTO v_v2_id      FROM wms.vendor WHERE name = 'V2';
    SELECT id INTO v_uom_pcs_id FROM wms.uom    WHERE name = 'PCS';
    SELECT id INTO v_uom_box_id FROM wms.uom    WHERE name = 'BOX24';

    -- First PO for V2
    SELECT id INTO v_po3_id FROM wms.purchase_order_header
    WHERE vendor_id = v_v2_id ORDER BY id LIMIT 1 OFFSET 0;

    SELECT me.id INTO v_ean_m01 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-001' ORDER BY me.id LIMIT 1;
    SELECT me.id INTO v_ean_m02 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-002' ORDER BY me.id LIMIT 1;
    SELECT me.id INTO v_ean_m03 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-003' ORDER BY me.id LIMIT 1;
    SELECT me.id INTO v_ean_m04 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-004' ORDER BY me.id LIMIT 1;
    SELECT me.id INTO v_ean_m05 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-005' ORDER BY me.id LIMIT 1;

    SELECT id INTO v_pod1_id FROM wms.purchase_order_details WHERE header_id = v_po3_id ORDER BY id LIMIT 1 OFFSET 0;
    SELECT id INTO v_pod2_id FROM wms.purchase_order_details WHERE header_id = v_po3_id ORDER BY id LIMIT 1 OFFSET 1;
    SELECT id INTO v_pod3_id FROM wms.purchase_order_details WHERE header_id = v_po3_id ORDER BY id LIMIT 1 OFFSET 2;
    SELECT id INTO v_pod4_id FROM wms.purchase_order_details WHERE header_id = v_po3_id ORDER BY id LIMIT 1 OFFSET 3;
    SELECT id INTO v_pod5_id FROM wms.purchase_order_details WHERE header_id = v_po3_id ORDER BY id LIMIT 1 OFFSET 4;

    SELECT id INTO v_inward_id FROM wms.insert_inward_header(
        CURRENT_DATE, v_v2_id, v_po3_id::TEXT, NULL, NULL, 0,
        'Inward for PO3 — V2 MAT-001..005', 1
    );
    -- expiry 12 months out
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m01, v_pod1_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 180.00, 216000.00, (CURRENT_DATE + INTERVAL '12 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m02, v_pod2_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 310.00, 372000.00, (CURRENT_DATE + INTERVAL '12 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m03, v_pod3_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 450.00, 540000.00, (CURRENT_DATE + INTERVAL '12 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m04, v_pod4_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 130.00, 156000.00, (CURRENT_DATE + INTERVAL '12 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m05, v_pod5_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 545.00, 654000.00, (CURRENT_DATE + INTERVAL '12 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
END $$;

-- Draft inward for PO4 (V2, MAT-006..010)
DO $$
DECLARE
    v_v2_id       INTEGER;
    v_po4_id      INTEGER;
    v_inward_id   INTEGER;
    v_uom_pcs_id  INTEGER;
    v_uom_box_id  INTEGER;
    v_ean_m06     INTEGER; v_ean_m07 INTEGER; v_ean_m08 INTEGER;
    v_ean_m09     INTEGER; v_ean_m10 INTEGER;
    v_pod1_id     INTEGER; v_pod2_id INTEGER; v_pod3_id INTEGER;
    v_pod4_id     INTEGER; v_pod5_id INTEGER;
BEGIN
    SELECT id INTO v_v2_id      FROM wms.vendor WHERE name = 'V2';
    SELECT id INTO v_uom_pcs_id FROM wms.uom    WHERE name = 'PCS';
    SELECT id INTO v_uom_box_id FROM wms.uom    WHERE name = 'BOX24';

    -- Second PO for V2
    SELECT id INTO v_po4_id FROM wms.purchase_order_header
    WHERE vendor_id = v_v2_id ORDER BY id LIMIT 1 OFFSET 1;

    SELECT me.id INTO v_ean_m06 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-006' ORDER BY me.id LIMIT 1;
    SELECT me.id INTO v_ean_m07 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-007' ORDER BY me.id LIMIT 1;
    SELECT me.id INTO v_ean_m08 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-008' ORDER BY me.id LIMIT 1;
    SELECT me.id INTO v_ean_m09 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-009' ORDER BY me.id LIMIT 1;
    SELECT me.id INTO v_ean_m10 FROM wms.material_ean me JOIN wms.material m ON m.id = me.material_id WHERE m.name = 'MAT-010' ORDER BY me.id LIMIT 1;

    SELECT id INTO v_pod1_id FROM wms.purchase_order_details WHERE header_id = v_po4_id ORDER BY id LIMIT 1 OFFSET 0;
    SELECT id INTO v_pod2_id FROM wms.purchase_order_details WHERE header_id = v_po4_id ORDER BY id LIMIT 1 OFFSET 1;
    SELECT id INTO v_pod3_id FROM wms.purchase_order_details WHERE header_id = v_po4_id ORDER BY id LIMIT 1 OFFSET 2;
    SELECT id INTO v_pod4_id FROM wms.purchase_order_details WHERE header_id = v_po4_id ORDER BY id LIMIT 1 OFFSET 3;
    SELECT id INTO v_pod5_id FROM wms.purchase_order_details WHERE header_id = v_po4_id ORDER BY id LIMIT 1 OFFSET 4;

    SELECT id INTO v_inward_id FROM wms.insert_inward_header(
        CURRENT_DATE, v_v2_id, v_po4_id::TEXT, NULL, NULL, 0,
        'Inward for PO4 — V2 MAT-006..010', 1
    );
    -- expiry 18 months out
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m06, v_pod1_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 250.00, 300000.00, (CURRENT_DATE + INTERVAL '18 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m07, v_pod2_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 380.00, 456000.00, (CURRENT_DATE + INTERVAL '18 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m08, v_pod3_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 680.00, 816000.00, (CURRENT_DATE + INTERVAL '18 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m09, v_pod4_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 105.00, 126000.00, (CURRENT_DATE + INTERVAL '18 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
    PERFORM wms.insert_inward_details(v_inward_id, v_ean_m10, v_pod5_id, v_uom_box_id, v_uom_pcs_id, v_uom_box_id, 1200, 50, 820.00, 984000.00, (CURRENT_DATE + INTERVAL '18 months')::DATE, UPPER(LEFT(MD5(RANDOM()::TEXT), 10)), NULL, 1);
END $$;
