SET SQL_SAFE_UPDATES=0;

/* ---------------- tenants ----------------
   Account 6 is the client that owns every real row; the rest are test tenants
   with faker names. All of them get plausible business identities instead. */
UPDATE accounts SET
  name = CASE account_id
    WHEN 6 THEN 'Lagoon Leisure Group'
    ELSE ELT(1 + (account_id % 20),
      'Kopi Lane Cafe','Bright Bites Sdn Bhd','Harbour Grill','Tropika Ventures','Nusantara Eats',
      'Cendana Retail','Summit Play','Aurora Wellness','Bayu Bistro','Kirana Kitchen',
      'Muara Coffee','Serai Group','Vertex Leisure','Anggerik Spa','Lumen Studios',
      'Selasih Foods','Damai Resorts','Pelangi Play','Teratai Cafe','Meranti Holdings')
  END,
  company_name = CASE account_id
    WHEN 6 THEN 'Lagoon Leisure Group Sdn Bhd'
    ELSE CONCAT(ELT(1 + (account_id % 20),
      'Kopi Lane Cafe','Bright Bites','Harbour Grill','Tropika Ventures','Nusantara Eats',
      'Cendana Retail','Summit Play','Aurora Wellness','Bayu Bistro','Kirana Kitchen',
      'Muara Coffee','Serai Group','Vertex Leisure','Anggerik Spa','Lumen Studios',
      'Selasih Foods','Damai Resorts','Pelangi Play','Teratai Cafe','Meranti Holdings'), ' Sdn Bhd')
  END,
  email = CONCAT('tenant', account_id, '@example.com'),
  telephone = CONCAT('1', 1 + (account_id % 9), '-', LPAD((account_id * 37) % 1000, 3, '0'), ' ', LPAD((account_id * 91) % 10000, 4, '0')),
  address = CONCAT('Level ', 1 + (account_id % 20), ', Menara Damai, Jalan Kenanga, 50450 Kuala Lumpur');

/* ---------------- outlets ---------------- */
UPDATE stores SET
  name = CASE store_id
    WHEN 1 THEN 'Lagoon Park Kuala Terengganu'
    WHEN 2 THEN 'Lagoon Park Melaka'
    WHEN 3 THEN 'Sakura Village Ipoh'
    WHEN 4 THEN 'Crestline Barbershop'
    WHEN 5 THEN 'Franchise Pilot'
    WHEN 6 THEN 'Franchise Pilot 3'
    ELSE CONCAT('Outlet ', store_id)
  END,
  slug = CASE store_id
    WHEN 1 THEN 'lagoon-park-kuala-terengganu'
    WHEN 2 THEN 'lagoon-park-melaka'
    WHEN 3 THEN 'sakura-village-ipoh'
    WHEN 4 THEN 'crestline-barbershop'
    WHEN 5 THEN 'franchise-pilot'
    WHEN 6 THEN 'franchise-pilot-3'
    ELSE CONCAT('outlet-', store_id)
  END,
  custom_domain = CASE store_id
    WHEN 1 THEN 'shop.lagoonpark.example.com'
    WHEN 2 THEN 'melaka.lagoonpark.example.com'
    ELSE NULL
  END,
  email = CONCAT('outlet', store_id, '@example.com'),
  telephone = CONCAT('9', store_id, '-', LPAD((store_id * 137) % 1000, 3, '0'), ' ', LPAD((store_id * 71) % 10000, 4, '0')),
  address = CONCAT('No ', 1 + (store_id * 7) % 120, ', Jalan Damai, Taman Sri Kenanga'),
  website = CONCAT('https://outlet', store_id, '.example.com'),
  gst_no = IF(gst_no IS NULL OR gst_no = '', gst_no, CONCAT('GST', LPAD((store_id * 13) % 1000000000, 9, '0'))),
  sst_no = IF(sst_no IS NULL OR sst_no = '', sst_no, CONCAT('W10-1808-', LPAD((store_id * 17) % 100000000, 8, '0'))),
  tin    = IF(tin IS NULL OR tin = '', tin, CONCAT('C', LPAD((store_id * 23) % 10000000000, 10, '0'))),
  brn    = IF(brn IS NULL OR brn = '', brn, CONCAT(LPAD((store_id * 29) % 1000000, 6, '0'), '-', LPAD(store_id, 2, '0')));

/* ---------------- staff (backoffice guard) ----------------
   password check is bcrypt(salt . plaintext); salt emptied so the plaintext
   'password' matches the stored hash. */
UPDATE employees SET
  first_name = ELT(1 + (employee_id % 20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),
  last_name  = ELT(1 + ((employee_id * 7) % 20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju'),
  email = CONCAT('staff', employee_id, '@example.com'),
  telephone = CONCAT('1', 1 + (employee_id % 9), '-', LPAD(employee_id % 1000, 3, '0'), ' ', LPAD((employee_id * 37) % 10000, 4, '0')),
  password = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  salt = '',
  passcode = LPAD((employee_id * 7919) % 1000000, 6, '0'),
  remember_token = NULL;

/* ---------------- platform users (backend guard) ---------------- */
UPDATE users SET
  name = CONCAT('Platform Admin ', id),
  email = CONCAT('platform', id, '@example.com'),
  password = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  salt = '',
  remember_token = NULL;

/* ---------------- customers ---------------- */
UPDATE customers SET
  first_name = ELT(1 + (customer_id % 20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),
  last_name  = ELT(1 + ((customer_id * 7) % 20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju'),
  email = CONCAT('customer', customer_id, '@example.com'),
  telephone = CONCAT('1', 1 + (customer_id % 9), '-', LPAD(customer_id % 1000, 3, '0'), ' ', LPAD((customer_id * 37) % 10000, 4, '0')),
  password = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  salt = '';

UPDATE customer_addresses SET
  address = CONCAT('No ', 1 + (customer_address_id % 180), ', ',
    ELT(1 + (customer_address_id % 8),'Jalan Kenanga','Jalan Melur 2','Jalan SS15/4','Jalan Damai','Persiaran Surian','Lorong Maarof','Jalan Setia Dagang','Jalan Puteri 1/2'), ', ',
    ELT(1 + ((customer_address_id * 5) % 8),'Taman Melawati','Taman Desa','Bandar Utama','Ara Damansara','Setia Alam','Bukit Jalil','Kota Damansara','Puchong Jaya')),
  postcode = ELT(1 + ((customer_address_id * 7) % 6),'47301','40150','50470','47620','41200','47100');

/* ---------------- guest details on orders, carts, bookings ---------------- */
UPDATE orders SET
  guest_first_name = IF(guest_first_name IS NULL OR guest_first_name='', guest_first_name,
    ELT(1 + (order_id % 20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan')),
  guest_last_name = IF(guest_last_name IS NULL OR guest_last_name='', guest_last_name,
    ELT(1 + ((order_id * 7) % 20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju')),
  guest_email = IF(guest_email IS NULL OR guest_email='', guest_email, CONCAT('guest', order_id, '@example.com')),
  guest_telephone = IF(guest_telephone IS NULL OR guest_telephone='', guest_telephone,
    CONCAT('1', 1 + (order_id % 9), '-', LPAD(order_id % 1000, 3, '0'), ' ', LPAD((order_id * 37) % 10000, 4, '0'))),
  remark = IF(remark IS NULL OR remark='', remark, ELT(1 + (order_id % 5),
    'Please prepare for 2pm collection.','Allergy note: no peanuts.','Birthday visit, add candles.','Group booking, one receipt.','Call on arrival at the gate.'));

UPDATE carts SET
  guest_first_name = IF(guest_first_name IS NULL OR guest_first_name='', guest_first_name, CONCAT('Guest ', cart_id)),
  guest_last_name = IF(guest_last_name IS NULL OR guest_last_name='', guest_last_name, 'Visitor'),
  guest_email = IF(guest_email IS NULL OR guest_email='', guest_email, CONCAT('guest', cart_id, '@example.com')),
  guest_telephone = IF(guest_telephone IS NULL OR guest_telephone='', guest_telephone,
    CONCAT('1', 1 + (cart_id % 9), '-', LPAD(cart_id % 1000, 3, '0'), ' ', LPAD((cart_id * 37) % 10000, 4, '0'))),
  remark = IF(remark IS NULL OR remark='', remark, 'Cart note.');

UPDATE bookings SET
  guest_first_name = IF(guest_first_name IS NULL OR guest_first_name='', guest_first_name,
    ELT(1 + (booking_id % 20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan')),
  guest_last_name = IF(guest_last_name IS NULL OR guest_last_name='', guest_last_name,
    ELT(1 + ((booking_id * 7) % 20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju')),
  guest_email = IF(guest_email IS NULL OR guest_email='', guest_email, CONCAT('guest', booking_id, '@example.com')),
  guest_telephone = IF(guest_telephone IS NULL OR guest_telephone='', guest_telephone,
    CONCAT('1', 1 + (booking_id % 9), '-', LPAD(booking_id % 1000, 3, '0'), ' ', LPAD((booking_id * 37) % 10000, 4, '0')));

/* ---------------- free text ---------------- */
UPDATE order_details SET remark = IF(remark IS NULL OR remark='', remark, 'Line note.');
UPDATE cart_details SET remark = IF(remark IS NULL OR remark='', remark, 'Line note.');
UPDATE order_histories SET remark = IF(remark IS NULL OR remark='', remark, 'Status updated.');
UPDATE quotation_histories SET remark = IF(remark IS NULL OR remark='', remark, 'Quotation updated.');
UPDATE purchase_order_histories SET remark = IF(remark IS NULL OR remark='', remark, 'Purchase order updated.');
UPDATE quotations SET remark = IF(remark IS NULL OR remark='', remark, 'Quotation note.');
UPDATE purchase_orders SET note = IF(note IS NULL OR note='', note, 'Purchase order note.');
UPDATE stock_movements SET remark = IF(remark IS NULL OR remark='', remark, 'Stock adjustment.');
UPDATE payment_proofs SET remark = IF(remark IS NULL OR remark='', remark, 'Payment proof uploaded.');
UPDATE pos_sessions SET note = IF(note IS NULL OR note='', note, 'Shift note.');

/* ---------------- other people ---------------- */
UPDATE suppliers SET
  first_name = ELT(1 + (supplier_id % 20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),
  last_name  = ELT(1 + ((supplier_id * 7) % 20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju'),
  email = CONCAT('supplier', supplier_id, '@example.com'),
  telephone = CONCAT('1', 1 + (supplier_id % 9), '-', LPAD(supplier_id % 1000, 3, '0'), ' ', LPAD((supplier_id * 37) % 10000, 4, '0')),
  company_name = CONCAT(ELT(1 + (supplier_id % 8),'Aurora','Lumen','Bayu','Anggerik','Vertex','Serai','Muara','Cendana'), ' Supplies Sdn Bhd'),
  address = CONCAT('Lot ', 1 + (supplier_id % 90), ', Jalan Perindustrian, Shah Alam'),
  postcode = '40150';

UPDATE assignees SET
  first_name = ELT(1 + (assignee_id % 20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),
  last_name  = ELT(1 + ((assignee_id * 7) % 20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju'),
  email = CONCAT('assignee', assignee_id, '@example.com'),
  phone_number = CONCAT('1', 1 + (assignee_id % 9), '-', LPAD(assignee_id % 1000, 3, '0'), ' ', LPAD((assignee_id * 37) % 10000, 4, '0'));

UPDATE feedback SET
  customer_name = CONCAT('Visitor ', id),
  customer_email = CONCAT('visitor', id, '@example.com');

UPDATE insight SET
  customer_name = CONCAT('Visitor ', id),
  customer_email = CONCAT('visitor', id, '@example.com');

UPDATE access_logs SET person_name = CONCAT('Visitor ', id);
UPDATE user_registrations SET name = CONCAT('Registration ', id);
UPDATE devices SET communication_password = NULL;

/* ---------------- tokens, sessions, queues ---------------- */
DELETE FROM sessions;
DELETE FROM password_resets;
DELETE FROM password_reset_tokens;
DELETE FROM personal_access_tokens;
DELETE FROM failed_jobs;
DELETE FROM jobs;
DELETE FROM job_batches;
DELETE FROM gkash_payment_logs;
DELETE FROM gkash_ewallet_logs;
