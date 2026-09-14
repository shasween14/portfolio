SET SQL_SAFE_UPDATES=0;

/* a delivery category named after a person is leftover test data */
UPDATE delivery_categories SET name = 'Own Rider' WHERE id = 13;
UPDATE deliveries SET delivery_category_id = 13 WHERE delivery_category_id IS NULL;

/* assign riders to most of the near-term deliveries, leave some unassigned */
UPDATE orders SET delivery_id = ELT(1 + (id % 8), 1, 2, 13, 14, 15, 16, 17, 18)
  WHERE delivery_date BETWEEN CURDATE() - INTERVAL 10 DAY AND CURDATE() + INTERVAL 10 DAY
    AND id % 4 <> 0;

/* orders imported without an address show as ", 00000 , , Malaysia" */
UPDATE orders SET
  shipping_address = CONCAT('No ', 1 + ((id * 3) % 180), ', ',
    ELT(1+((id*3)%10),'Jalan Kenanga','Jalan Melur 2','Jalan SS15/4','Jalan Damai','Persiaran Surian','Jalan Bukit Kiara','Lorong Maarof','Jalan Ampang Hilir','Jalan Setia Dagang','Jalan Puteri 1/2'), ', ',
    ELT(1+((id*5)%10),'Taman Melawati','Taman Desa','Bandar Utama','Ara Damansara','Mont Kiara','Setia Alam','Bukit Jalil','Kota Damansara','Puchong Jaya','Seri Kembangan')),
  shipping_city  = ELT(1+((id*7)%6),'Petaling Jaya','Shah Alam','Kuala Lumpur','Subang Jaya','Klang','Puchong'),
  shipping_state = ELT(1+((id*7)%6),'Selangor','Selangor','Kuala Lumpur','Selangor','Selangor','Selangor'),
  shipping_postal = ELT(1+((id*7)%6),'47301','40150','50470','47620','41200','47100')
  WHERE (shipping_address IS NULL OR shipping_address = '')
    AND delivery_date BETWEEN CURDATE() - INTERVAL 30 DAY AND CURDATE() + INTERVAL 30 DAY;

UPDATE orders SET
  shipping_name = CONCAT(
    ELT(1+((id*3)%20),'Aisyah','Nurul','Farah','Wei Ling','Mei Yee','Kavitha','Priya','Daniel','Hafiz','Zulhilmi','Jason','Adrian','Siti','Amira','Chong Wei','Suresh','Elaine','Michelle','Ahmad','Ridzuan'),' ',
    ELT(1+((id*11)%20),'Rahman','Ibrahim','Tan','Lim','Wong','Chan','Nair','Kumar','Abdullah','Yusof','Ng','Lee','Ooi','Devi','Chia','Sulaiman','Aziz','Teo','Goh','Raju')),
  shipping_contact = CONCAT('01', 1+((id*3)%9), '-', LPAD((id*3)%1000,3,'0'), ' ', LPAD((id*41)%10000,4,'0'))
  WHERE (shipping_name IS NULL OR shipping_name = '')
    AND delivery_date BETWEEN CURDATE() - INTERVAL 30 DAY AND CURDATE() + INTERVAL 30 DAY;

/* SKUs on the lines of near-term orders */
UPDATE order_details d
  JOIN orders o ON o.id = d.order_id
  SET d.sku = CONCAT('FB-', ELT(1+(d.id%5),'BQT','VAS','BOX','PLT','GFT'), '-', LPAD(100 + (d.id % 400), 3, '0'))
  WHERE (d.sku IS NULL OR d.sku = '')
    AND o.delivery_date BETWEEN CURDATE() - INTERVAL 30 DAY AND CURDATE() + INTERVAL 30 DAY;

/* a few operational remarks on today's board */
UPDATE orders SET remark = ELT(1+(id%6),
    'Please deliver before 12pm.','Leave with the guardhouse if no answer.','Call on arrival, gated community.',
    'Gift wrap in kraft paper.','Card message to be handwritten.','Office lobby drop-off, weekdays only.')
  WHERE (remark IS NULL OR remark = '')
    AND delivery_date BETWEEN CURDATE() - INTERVAL 2 DAY AND CURDATE() + INTERVAL 2 DAY
    AND id % 3 = 0;
