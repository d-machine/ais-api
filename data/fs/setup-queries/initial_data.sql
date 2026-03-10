INSERT INTO administration.user (username, email, first_name, last_name, password, reports_to, lub) VALUES
('admin', 'LQrGq@example.com', 'Admin', 'Admin', 'admin', 0, 1);

INSERT INTO administration.role (name, descr, lub) VALUES
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
(111, 'Transport', 'list-transports', 3, 1)
;

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

INSERT INTO wms.vendor (
  category_id, name,
  add1, add2, add3,
  city_id, district_id, state_id, country_id, pincode,
  gstno, pan_no, lub
) VALUES (
  (SELECT id FROM wms.vendor_category WHERE name = 'VC1'),
  'V1',
  '12 Industrial Area', 'Sector 18', 'Phase II',
  (SELECT id FROM wms.city     WHERE code = 'GGN'),
  (SELECT id FROM wms.district WHERE code = 'GGN'),
  (SELECT id FROM wms.state    WHERE name = 'Haryana'),
  (SELECT id FROM wms.country  WHERE code = 'IN'),
  '122015',
  'GST06ABCDE1234F1Z5', 'ABCDE1234F',
  1
);

INSERT INTO wms.vendor_contact_details (vendor_id, name, telephone, email, position, descr, lub) VALUES
(
  (SELECT id FROM wms.vendor WHERE name = 'V1'),
  'P1', '9876543210', 'p1@v1vendor.com', 'Manager', 'Primary contact', 1
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

INSERT INTO wms.party (
  category_id, name,
  add1, add2, add3,
  city_id, district_id, state_id, country_id, pincode,
  gstno, pan_no, lub
) VALUES (
  (SELECT id FROM wms.party_category WHERE name = 'PC1'),
  'P1',
  '45 Commerce Park', 'Sector 32', 'Block A',
  (SELECT id FROM wms.city     WHERE code = 'GGN'),
  (SELECT id FROM wms.district WHERE code = 'GGN'),
  (SELECT id FROM wms.state    WHERE name = 'Haryana'),
  (SELECT id FROM wms.country  WHERE code = 'IN'),
  '122001',
  'GST06XYZAB5678G1Z3', 'XYZAB5678G',
  1
);

INSERT INTO wms.party_contact_details (party_id, name, telephone, email, position, descr, lub) VALUES
(
  (SELECT id FROM wms.party WHERE name = 'P1'),
  'P1', '9812345670', 'p1@p1party.com', 'Manager', 'Primary contact', 1
);
