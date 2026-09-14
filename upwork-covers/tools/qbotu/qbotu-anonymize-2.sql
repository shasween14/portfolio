SET SQL_SAFE_UPDATES=0;

/* tenants.id is a uuid string, so index the pools off CRC32(id) */
UPDATE tenants SET
  name = CONCAT(
    ELT(1 + (CRC32(id) % 20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),
    ' ',
    ELT(1 + ((CRC32(id) * 7) % 20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju')),
  phone = CONCAT('01', 1 + (CRC32(id) % 9), '-', LPAD(CRC32(id) % 1000, 3, '0'), ' ', LPAD((CRC32(id) * 37) % 10000, 4, '0')),
  card_code = CONCAT('CARD', LPAD((CRC32(id) * 7919) % 100000000, 8, '0'));

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

UPDATE employee_activity_log l LEFT JOIN merchant_users u ON u.id = l.staff_id
  SET l.staff_name = COALESCE(u.name, CONCAT('Staff ', LEFT(REPLACE(l.id, '-', ''), 4)));
UPDATE staff_attendance a LEFT JOIN merchant_users u ON u.id = a.staff_id
  SET a.staff_name = COALESCE(u.name, CONCAT('Staff ', LEFT(REPLACE(a.id, '-', ''), 4)));
UPDATE device_binding_logs SET
  performed_by_user_name = CONCAT('Staff ', LEFT(REPLACE(id, '-', ''), 4)),
  outlet_name = 'Amber Bites Bangsar';

UPDATE kiosk_devices SET kiosk_name = CONCAT('Kiosk ', UPPER(LEFT(REPLACE(id, '-', ''), 3)));
UPDATE pos_devices SET pos_name = CONCAT('POS ', UPPER(LEFT(REPLACE(id, '-', ''), 3)));
UPDATE printers SET name = CONCAT('Receipt Printer ', UPPER(LEFT(REPLACE(id, '-', ''), 3)));

DELETE FROM personal_access_tokens;
DELETE FROM hq_sessions;
DELETE FROM face_encodings;
DELETE FROM face_checkin_logs;
