SET SQL_SAFE_UPDATES=0;

/* Deterministic fake identities, indexed off the row id.
   first: ELT(1+(id%20), ...)   last: ELT(1+((id*7)%20), ...) */

/* ---------------- members ---------------- */
UPDATE members SET
  name = CONCAT(
    ELT(1+(id%20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),
    ' ',
    ELT(1+((id*7)%20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju')),
  email = CONCAT('member', id, '@example.com'),
  company_email = IF(company_email IS NULL OR company_email='', company_email, CONCAT('accounts', id, '@example.com')),
  contact = CONCAT('01', 1+(id%9), '-', LPAD(id%1000,3,'0'), ' ', LPAD((id*37)%10000,4,'0')),
  company = IF(company IS NULL OR company='', company, CONCAT(
    ELT(1+(id%10),'Aurora','Lumen','Bayu','Anggerik','Vertex','Serai','Muara','Cendana','Nusantara','Kirana'),' ',
    ELT(1+((id*3)%10),'Trading','Resources','Solutions','Marketing','Ventures','Supplies','Enterprise','Holdings','Retail','Logistics'),' Sdn Bhd')),
  identity_number = IF(identity_number IS NULL OR identity_number='', identity_number, CONCAT(LPAD((id*13)%1000000,6,'0'),'-',LPAD(id%100,2,'0'),'-',LPAD((id*7)%10000,4,'0'))),
  tin_number = IF(tin_number IS NULL OR tin_number='', tin_number, CONCAT('IG', LPAD((id*17)%100000000,11,'0'))),
  sst_number = IF(sst_number IS NULL OR sst_number='', sst_number, CONCAT('W10-1808-', LPAD(id%100000000,8,'0'))),
  password = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  remember_token = NULL,
  shopify_member_id = IF(shopify_member_id IS NULL OR shopify_member_id='', shopify_member_id, CONCAT('7', LPAD(id, 11, '0')));

/* ---------------- member addresses ---------------- */
UPDATE member_addresses SET
  name = CONCAT(
    ELT(1+(id%20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),
    ' ',
    ELT(1+((id*7)%20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju')),
  contact = CONCAT('01', 1+(id%9), '-', LPAD(id%1000,3,'0'), ' ', LPAD((id*37)%10000,4,'0')),
  company = IF(company IS NULL OR company='', company, CONCAT(
    ELT(1+(id%10),'Aurora','Lumen','Bayu','Anggerik','Vertex','Serai','Muara','Cendana','Nusantara','Kirana'),' ',
    ELT(1+((id*3)%10),'Trading','Resources','Solutions','Marketing','Ventures','Supplies','Enterprise','Holdings','Retail','Logistics'),' Sdn Bhd')),
  address = CONCAT('No ', 1+(id%180), ', ',
    ELT(1+(id%10),'Jalan Kenanga','Jalan Melur 2','Jalan SS15/4','Jalan Damai','Persiaran Surian','Jalan Bukit Kiara','Lorong Maarof','Jalan Ampang Hilir','Jalan Setia Dagang','Jalan Puteri 1/2'), ', ',
    ELT(1+((id*5)%10),'Taman Melawati','Taman Desa','Bandar Utama','Ara Damansara','Mont Kiara','Setia Alam','Bukit Jalil','Kota Damansara','Puchong Jaya','Seri Kembangan')),
  shopify_member_address_id = IF(shopify_member_address_id IS NULL OR shopify_member_address_id='', shopify_member_address_id, CONCAT('9', LPAD(id, 11, '0')));

/* ---------------- orders ---------------- */
UPDATE orders SET
  name = CONCAT(
    ELT(1+(id%20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),
    ' ',
    ELT(1+((id*7)%20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju')),
  email = CONCAT('customer', id, '@example.com'),
  contact = CONCAT('01', 1+(id%9), '-', LPAD(id%1000,3,'0'), ' ', LPAD((id*37)%10000,4,'0')),
  billing_name = IF(billing_name IS NULL OR billing_name='', billing_name, CONCAT(
    ELT(1+(id%20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),' ',
    ELT(1+((id*7)%20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju'))),
  billing_contact = IF(billing_contact IS NULL OR billing_contact='', billing_contact, CONCAT('01', 1+(id%9), '-', LPAD(id%1000,3,'0'), ' ', LPAD((id*37)%10000,4,'0'))),
  billing_company = IF(billing_company IS NULL OR billing_company='', billing_company, CONCAT(
    ELT(1+(id%10),'Aurora','Lumen','Bayu','Anggerik','Vertex','Serai','Muara','Cendana','Nusantara','Kirana'),' ',
    ELT(1+((id*3)%10),'Trading','Resources','Solutions','Marketing','Ventures','Supplies','Enterprise','Holdings','Retail','Logistics'),' Sdn Bhd')),
  billing_address = IF(billing_address IS NULL OR billing_address='', billing_address, CONCAT('No ', 1+(id%180), ', ',
    ELT(1+(id%10),'Jalan Kenanga','Jalan Melur 2','Jalan SS15/4','Jalan Damai','Persiaran Surian','Jalan Bukit Kiara','Lorong Maarof','Jalan Ampang Hilir','Jalan Setia Dagang','Jalan Puteri 1/2'), ', ',
    ELT(1+((id*5)%10),'Taman Melawati','Taman Desa','Bandar Utama','Ara Damansara','Mont Kiara','Setia Alam','Bukit Jalil','Kota Damansara','Puchong Jaya','Seri Kembangan'))),
  shipping_name = IF(shipping_name IS NULL OR shipping_name='', shipping_name, CONCAT(
    ELT(1+((id*3)%20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),' ',
    ELT(1+((id*11)%20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju'))),
  shipping_contact = IF(shipping_contact IS NULL OR shipping_contact='', shipping_contact, CONCAT('01', 1+((id*3)%9), '-', LPAD((id*3)%1000,3,'0'), ' ', LPAD((id*41)%10000,4,'0'))),
  shipping_company = IF(shipping_company IS NULL OR shipping_company='', shipping_company, CONCAT(
    ELT(1+(id%10),'Aurora','Lumen','Bayu','Anggerik','Vertex','Serai','Muara','Cendana','Nusantara','Kirana'),' ',
    ELT(1+((id*3)%10),'Trading','Resources','Solutions','Marketing','Ventures','Supplies','Enterprise','Holdings','Retail','Logistics'),' Sdn Bhd')),
  shipping_address = IF(shipping_address IS NULL OR shipping_address='', shipping_address, CONCAT('No ', 1+((id*3)%180), ', ',
    ELT(1+((id*3)%10),'Jalan Kenanga','Jalan Melur 2','Jalan SS15/4','Jalan Damai','Persiaran Surian','Jalan Bukit Kiara','Lorong Maarof','Jalan Ampang Hilir','Jalan Setia Dagang','Jalan Puteri 1/2'), ', ',
    ELT(1+((id*5)%10),'Taman Melawati','Taman Desa','Bandar Utama','Ara Damansara','Mont Kiara','Setia Alam','Bukit Jalil','Kota Damansara','Puchong Jaya','Seri Kembangan'))),
  remark = IF(remark IS NULL OR remark='', remark, ELT(1+(id%6),
    'Please deliver before 12pm.','Leave with the guardhouse if no answer.','Call on arrival, gated community.','Gift wrap in kraft paper.','Card message to be handwritten.','Office lobby drop-off, weekdays only.')),
  notes = IF(notes IS NULL OR notes='', notes, ELT(1+(id%4),
    'Customer confirmed delivery slot by phone.','Reschedule requested once, now confirmed.','Corporate account, invoice on 30-day terms.','Repeat order from previous month.')),
  board_remark = IF(board_remark IS NULL OR board_remark='', board_remark, ELT(1+(id%3),
    'Prep stems the night before.','Double-check ribbon colour.','Priority run, first van out.')),
  tracking_number = IF(tracking_number IS NULL OR tracking_number='', tracking_number, CONCAT('EP', LPAD((id*97)%1000000000,9,'0'), 'MY')),
  shopify_order_id = IF(shopify_order_id IS NULL OR shopify_order_id='', shopify_order_id, CONCAT('5', LPAD(id, 11, '0')));

/* ---------------- archived orders ---------------- */
UPDATE past_orders SET
  name = CONCAT(
    ELT(1+(id%20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),' ',
    ELT(1+((id*7)%20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju')),
  email = CONCAT('customer', id, '@example.com'),
  contact = CONCAT('01', 1+(id%9), '-', LPAD(id%1000,3,'0'), ' ', LPAD((id*37)%10000,4,'0')),
  billing_name = IF(billing_name IS NULL OR billing_name='', billing_name, CONCAT('Customer ', id)),
  billing_contact = IF(billing_contact IS NULL OR billing_contact='', billing_contact, CONCAT('01', 1+(id%9), '-', LPAD(id%1000,3,'0'), ' ', LPAD((id*37)%10000,4,'0'))),
  billing_address = IF(billing_address IS NULL OR billing_address='', billing_address, CONCAT('No ', 1+(id%180), ', Jalan Kenanga, Taman Melawati')),
  shipping_name = IF(shipping_name IS NULL OR shipping_name='', shipping_name, CONCAT('Recipient ', id)),
  shipping_contact = IF(shipping_contact IS NULL OR shipping_contact='', shipping_contact, CONCAT('01', 1+((id*3)%9), '-', LPAD((id*3)%1000,3,'0'), ' ', LPAD((id*41)%10000,4,'0'))),
  shipping_company = IF(shipping_company IS NULL OR shipping_company='', shipping_company, 'Aurora Trading Sdn Bhd'),
  shipping_address = IF(shipping_address IS NULL OR shipping_address='', shipping_address, CONCAT('No ', 1+((id*3)%180), ', Jalan Damai, Bandar Utama')),
  remark = IF(remark IS NULL OR remark='', remark, 'Delivery instructions on file.'),
  notes = IF(notes IS NULL OR notes='', notes, 'Archived order.'),
  board_remark = NULL,
  tracking_number = IF(tracking_number IS NULL OR tracking_number='', tracking_number, CONCAT('EP', LPAD((id*97)%1000000000,9,'0'), 'MY'));

/* ---------------- order lines carry a recipient too ---------------- */
UPDATE order_details SET
  name = IF(name IS NULL OR name='', name, CONCAT(
    ELT(1+(id%20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),' ',
    ELT(1+((id*7)%20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju'))),
  contact = IF(contact IS NULL OR contact='', contact, CONCAT('01', 1+(id%9), '-', LPAD(id%1000,3,'0'), ' ', LPAD((id*37)%10000,4,'0')));

UPDATE past_order_details SET
  name = IF(name IS NULL OR name='', name, CONCAT('Recipient ', id)),
  contact = IF(contact IS NULL OR contact='', contact, CONCAT('01', 1+(id%9), '-', LPAD(id%1000,3,'0'), ' ', LPAD((id*37)%10000,4,'0')));

/* ---------------- invoices ---------------- */
UPDATE invoices SET
  billing_name = IF(billing_name IS NULL OR billing_name='', billing_name, CONCAT(
    ELT(1+(id%20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),' ',
    ELT(1+((id*7)%20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju'))),
  billing_contact = IF(billing_contact IS NULL OR billing_contact='', billing_contact, CONCAT('01', 1+(id%9), '-', LPAD(id%1000,3,'0'), ' ', LPAD((id*37)%10000,4,'0'))),
  billing_address = IF(billing_address IS NULL OR billing_address='', billing_address, CONCAT('No ', 1+(id%180), ', Jalan Kenanga, Taman Melawati')),
  shipping_name = IF(shipping_name IS NULL OR shipping_name='', shipping_name, CONCAT(
    ELT(1+((id*3)%20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),' ',
    ELT(1+((id*11)%20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju'))),
  shipping_contact = IF(shipping_contact IS NULL OR shipping_contact='', shipping_contact, CONCAT('01', 1+((id*3)%9), '-', LPAD((id*3)%1000,3,'0'), ' ', LPAD((id*41)%10000,4,'0'))),
  shipping_company = IF(shipping_company IS NULL OR shipping_company='', shipping_company, 'Aurora Trading Sdn Bhd'),
  shipping_address = IF(shipping_address IS NULL OR shipping_address='', shipping_address, CONCAT('No ', 1+((id*3)%180), ', Jalan Damai, Bandar Utama'));

/* ---------------- deliveries ---------------- */
UPDATE deliveries SET
  name = IF(name IS NULL OR name='', name, CONCAT(
    ELT(1+(id%20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),' ',
    ELT(1+((id*7)%20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju'))),
  email = IF(email IS NULL OR email='', email, CONCAT('delivery', id, '@example.com')),
  contact = IF(contact IS NULL OR contact='', contact, CONCAT('01', 1+(id%9), '-', LPAD(id%1000,3,'0'), ' ', LPAD((id*37)%10000,4,'0'))),
  address = IF(address IS NULL OR address='', address, CONCAT('No ', 1+(id%180), ', Jalan Kenanga, Taman Melawati'));

/* ---------------- staff users ---------------- */
UPDATE users SET
  password = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  email = CONCAT('staff', id, '@example.com'),
  contact = CONCAT('03-2', LPAD(id%1000,3,'0'), ' ', LPAD((id*37)%10000,4,'0')),
  address = IF(address IS NULL OR address='', address, 'Lot 12, Jalan Kenanga, Taman Melawati'),
  id_number = IF(id_number IS NULL OR id_number='', id_number, CONCAT(LPAD((id*13)%1000000,6,'0'),'-',LPAD(id%100,2,'0'),'-',LPAD((id*7)%10000,4,'0'))),
  remember_token = NULL,
  last_session = NULL;

/* ---------------- free text and audit trails ---------------- */
UPDATE order_histories SET remark = IF(remark IS NULL OR remark='', remark, 'Status updated by operations.');
UPDATE past_order_histories SET remark = IF(remark IS NULL OR remark='', remark, 'Status updated by operations.');
UPDATE credit_histories SET remark = IF(remark IS NULL OR remark='', remark, 'Credit adjustment recorded.');
UPDATE leaves SET remark = IF(remark IS NULL OR remark='', remark, 'Leave application.');

/* ---------------- secrets, tokens, logs ---------------- */
UPDATE accounts SET google2fa_secret = NULL, otp_mobile = NULL, email = 'orders@example.com', contact = '03-2011 8800';
UPDATE payment_methods SET secret = NULL;
DELETE FROM login_logs;
DELETE FROM notifications;
DELETE FROM password_resets;
DELETE FROM member_password_resets;
DELETE FROM personal_access_tokens;
DELETE FROM failed_jobs;
DELETE FROM jobs;
