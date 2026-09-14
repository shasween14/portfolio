SET SQL_SAFE_UPDATES=0;

/* Roles for the tenant were left as keyboard-mash test data; give them the
   names a real operator would use and a permission set that differs per role. */
UPDATE roles SET name = '6.cashier',       display_name = 'Cashier'       WHERE id = 41;
UPDATE roles SET name = '6.kitchen',       display_name = 'Kitchen'       WHERE id = 43;
UPDATE roles SET name = '6.supervisor',    display_name = 'Supervisor'    WHERE id = 45;
UPDATE roles SET name = '6.marketing',     display_name = 'Marketing'     WHERE id = 51;
UPDATE roles SET name = '6.accounts',      display_name = 'Accounts'      WHERE id = 52;
UPDATE roles SET name = '6.store_manager', display_name = 'Store Manager' WHERE id = 53;

DELETE FROM role_has_permissions WHERE role_id IN (8, 41, 43, 45, 51, 52, 53);
INSERT INTO role_has_permissions (permission_id, role_id)
SELECT p.id, r.role_id FROM permissions p JOIN (
  SELECT 8  AS role_id, '1,8,10' AS perms UNION ALL
  SELECT 41, '1,8,10,15' UNION ALL
  SELECT 43, '1,8' UNION ALL
  SELECT 45, '1,2,3,4,8,9,10,13,24,25' UNION ALL
  SELECT 51, '1,16,17,18,24,25' UNION ALL
  SELECT 52, '1,8,9,15,19,28,29' UNION ALL
  SELECT 53, '1,2,3,4,5,6,7,8,9,10,11,12,13,14,22,24,25,27,30'
) r ON FIND_IN_SET(p.id, r.perms);

/* outlet addresses: faker left US cities behind */
UPDATE stores SET
  city = CASE store_id
    WHEN 1 THEN 'Kuala Terengganu'
    WHEN 2 THEN 'Melaka'
    WHEN 3 THEN 'Ipoh'
    WHEN 4 THEN 'Petaling Jaya'
    ELSE 'Shah Alam' END,
  state = CASE store_id
    WHEN 1 THEN 'Terengganu'
    WHEN 2 THEN 'Melaka'
    WHEN 3 THEN 'Perak'
    WHEN 4 THEN 'Selangor'
    ELSE 'Selangor' END,
  postcode = CASE store_id
    WHEN 1 THEN '21300' WHEN 2 THEN '75100' WHEN 3 THEN '31350' WHEN 4 THEN '47301' ELSE '40150' END,
  country = 'Malaysia';

/* a few sign-ups today so the dashboard member tile is not a flat zero */
UPDATE customers SET created_at = NOW() - INTERVAL (customer_id % 6) HOUR
  WHERE customer_id % 17 = 0;
