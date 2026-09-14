SET SQL_SAFE_UPDATES=0;

/* ---------------- merchants ----------------
   The working data carries one real client plus test companies named after
   real fast-food brands; both get fictional identities. */
UPDATE companies SET
  company_name = CASE company_slug
    WHEN 'amazing-bhd' THEN 'Amber Bites Sdn Bhd'
    WHEN 'ramly'       THEN 'Kopi Lane Cafe'
    WHEN 'king'        THEN 'Harbour Grill'
    WHEN 'kfc'         THEN 'Nusantara Eats'
    WHEN 'tttt'        THEN 'Tropika Ventures'
    WHEN 'testing'     THEN 'Cendana Retail'
    WHEN 'bab'         THEN 'Bayu Bistro'
    ELSE 'Summit Play' END,
  company_slug = CASE company_slug
    WHEN 'amazing-bhd' THEN 'amber-bites'
    WHEN 'ramly'       THEN 'kopi-lane'
    WHEN 'king'        THEN 'harbour-grill'
    WHEN 'kfc'         THEN 'nusantara-eats'
    WHEN 'tttt'        THEN 'tropika'
    WHEN 'testing'     THEN 'cendana'
    WHEN 'bab'         THEN 'bayu-bistro'
    ELSE 'summit-play' END,
  owner_name = CONCAT(
    ELT(1 + (CRC32(id) % 20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),
    ' ',
    ELT(1 + ((CRC32(id) * 7) % 20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju')),
  owner_email = CONCAT('owner-', company_slug, '@example.com');

/* ---------------- outlets ---------------- */
UPDATE outlets o JOIN companies c ON c.id = o.company_id SET
  o.name = CASE
    WHEN o.slug = 'amazing-bhd' THEN 'Amber Bites Bangsar'
    WHEN o.slug = 'textilis-veniam-delectus' THEN 'Amber Bites Mid Valley'
    ELSE CONCAT(c.company_name, ' Main Outlet') END,
  o.slug = CASE
    WHEN o.slug = 'amazing-bhd' THEN 'amber-bites-bangsar'
    WHEN o.slug = 'textilis-veniam-delectus' THEN 'amber-bites-mid-valley'
    ELSE CONCAT(c.company_slug, '-main-outlet') END,
  o.company_name = c.company_name,
  o.address = CONCAT('Lot ', 1 + (CRC32(o.id) % 90), ', Jalan Kenanga'),
  o.address_line_2 = NULL,
  o.city = ELT(1 + (CRC32(o.id) % 5), 'Kuala Lumpur', 'Petaling Jaya', 'Shah Alam', 'Subang Jaya', 'Cyberjaya'),
  o.state = 'Selangor',
  o.post_code = ELT(1 + (CRC32(o.id) % 5), '50450', '47301', '40150', '47620', '63000'),
  o.country = 'Malaysia',
  o.contact_phone = CONCAT('03-2', LPAD(CRC32(o.id) % 1000, 3, '0'), ' ', LPAD(CRC32(o.id) % 10000, 4, '0')),
  o.contact_email = CONCAT('outlet-', o.slug, '@example.com'),
  o.website = NULL,
  o.google_map_address = NULL,
  o.gst_id = NULL, o.sst_id = NULL, o.brn = NULL;

/* ---------------- staff and platform users ----------------
   bcrypt of "password" for every account so the apps can be driven. */
UPDATE merchant_users SET
  name = CONCAT(
    ELT(1 + (CRC32(id) % 20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),
    ' ',
    ELT(1 + ((CRC32(id) * 7) % 20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju')),
  email = CONCAT(role, '-', LEFT(REPLACE(id, '-', ''), 6), '@example.com'),
  phone = CONCAT('01', 1 + (CRC32(id) % 9), '-', LPAD(CRC32(id) % 1000, 3, '0'), ' ', LPAD((CRC32(id) * 7) % 10000, 4, '0')),
  password_hash = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi';

UPDATE hq_users SET
  name = CONCAT('Platform ', UPPER(LEFT(role, 1)), SUBSTRING(role, 2)),
  email = CONCAT(role, '@example.com'),
  password_hash = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi';

UPDATE hq_user_profiles SET phone = '03-2011 8800', bio = NULL, avatar_url = NULL;

/* ---------------- cardholders ---------------- */
UPDATE tenants SET
  name = CONCAT(
    ELT(1 + (id % 20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),
    ' ',
    ELT(1 + ((id * 7) % 20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju')),
  phone = CONCAT('01', 1 + (id % 9), '-', LPAD(id % 1000, 3, '0'), ' ', LPAD((id * 37) % 10000, 4, '0')),
  card_code = CONCAT('CARD', LPAD((id * 7919) % 100000000, 8, '0'));

/* ---------------- orders ---------------- */
UPDATE shop_orders SET
  customer_name = IF(customer_name IS NULL OR customer_name = '', customer_name, CONCAT(
    ELT(1 + (CRC32(id) % 20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),
    ' ',
    ELT(1 + ((CRC32(id) * 7) % 20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju'))),
  customer_email = IF(customer_email IS NULL OR customer_email = '', customer_email, CONCAT('customer-', LEFT(REPLACE(id, '-', ''), 6), '@example.com')),
  phone_number = IF(phone_number IS NULL OR phone_number = '', phone_number, CONCAT('01', 1 + (CRC32(id) % 9), '-', LPAD(CRC32(id) % 1000, 3, '0'), ' ', LPAD((CRC32(id) * 7) % 10000, 4, '0'))),
  delivery_address = IF(delivery_address IS NULL OR delivery_address = '', delivery_address, CONCAT('No ', 1 + (CRC32(id) % 180), ', Jalan Damai, Bandar Utama')),
  delivery_notes = IF(delivery_notes IS NULL OR delivery_notes = '', delivery_notes, 'Leave at the guardhouse.'),
  notes = IF(notes IS NULL OR notes = '', notes, 'Order note.'),
  cancellation_notes = IF(cancellation_notes IS NULL OR cancellation_notes = '', cancellation_notes, 'Cancelled at the counter.'),
  refund_notes = IF(refund_notes IS NULL OR refund_notes = '', refund_notes, 'Refund processed.');

UPDATE shop_orders o
  LEFT JOIN merchant_users u ON u.id = o.staff_id
  SET o.staff_name = IF(o.staff_name IS NULL OR o.staff_name = '', o.staff_name, COALESCE(u.name, 'Counter Staff')),
      o.staff_name_last_action = IF(o.staff_name_last_action IS NULL OR o.staff_name_last_action = '', o.staff_name_last_action, COALESCE(u.name, 'Counter Staff')),
      o.processed_by_staff_name = IF(o.processed_by_staff_name IS NULL OR o.processed_by_staff_name = '', o.processed_by_staff_name, COALESCE(u.name, 'Counter Staff'));

/* ---------------- activity logs ---------------- */
UPDATE employee_activity_log l LEFT JOIN merchant_users u ON u.id = l.staff_id
  SET l.staff_name = COALESCE(u.name, CONCAT('Staff ', LEFT(REPLACE(l.id, '-', ''), 4)));
UPDATE staff_attendance a LEFT JOIN merchant_users u ON u.id = a.staff_id
  SET a.staff_name = COALESCE(u.name, CONCAT('Staff ', LEFT(REPLACE(a.id, '-', ''), 4)));
UPDATE device_binding_logs SET
  performed_by_user_name = CONCAT('Staff ', LEFT(REPLACE(id, '-', ''), 4)),
  outlet_name = 'Amber Bites Bangsar';
UPDATE pos_actions_log SET metadata = NULL WHERE metadata IS NOT NULL;

/* ---------------- devices and printers ---------------- */
UPDATE kiosk_devices SET kiosk_name = CONCAT('Kiosk ', LEFT(REPLACE(id, '-', ''), 3));
UPDATE pos_devices SET pos_name = CONCAT('POS ', LEFT(REPLACE(id, '-', ''), 3));
UPDATE printers SET name = CONCAT('Receipt Printer ', LEFT(REPLACE(id, '-', ''), 3));

/* ---------------- tokens, sessions, biometrics, secrets ---------------- */
DELETE FROM personal_access_tokens;
DELETE FROM hq_sessions;
DELETE FROM face_encodings;
DELETE FROM face_checkin_logs;
UPDATE xero_settings SET client_secret = NULL WHERE client_secret IS NOT NULL;
UPDATE autocount_settings SET secret_key = NULL WHERE secret_key IS NOT NULL;
UPDATE sql_accounting_settings SET secret_key = NULL WHERE secret_key IS NOT NULL;
UPDATE live_display_settings SET display_password = NULL WHERE display_password IS NOT NULL;
