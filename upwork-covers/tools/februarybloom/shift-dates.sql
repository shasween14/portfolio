/* Roll the demo dataset forward so "today" sits inside the busy window.
   orders/past-orders: +778d puts 2024-07-24 (13 deliveries) on today.
   members: +341d, invoices: +369d so neither lands in the future. */
SET SQL_SAFE_UPDATES=0;

UPDATE orders SET
  delivery_date = DATE_ADD(delivery_date, INTERVAL 778 DAY),
  date          = DATE_ADD(date,          INTERVAL 778 DAY),
  due_date      = DATE_ADD(due_date,      INTERVAL 778 DAY),
  created_at    = DATE_ADD(created_at,    INTERVAL 778 DAY),
  updated_at    = DATE_ADD(updated_at,    INTERVAL 778 DAY);

UPDATE past_orders SET
  delivery_date = DATE_ADD(delivery_date, INTERVAL 778 DAY),
  date          = DATE_ADD(date,          INTERVAL 778 DAY),
  due_date      = DATE_ADD(due_date,      INTERVAL 778 DAY),
  created_at    = DATE_ADD(created_at,    INTERVAL 778 DAY),
  updated_at    = DATE_ADD(updated_at,    INTERVAL 778 DAY);

UPDATE order_histories SET
  created_at = DATE_ADD(created_at, INTERVAL 778 DAY),
  updated_at = DATE_ADD(updated_at, INTERVAL 778 DAY);

UPDATE past_order_histories SET
  created_at = DATE_ADD(created_at, INTERVAL 778 DAY),
  updated_at = DATE_ADD(updated_at, INTERVAL 778 DAY);

UPDATE order_details SET
  created_at = DATE_ADD(created_at, INTERVAL 778 DAY),
  updated_at = DATE_ADD(updated_at, INTERVAL 778 DAY);

/* stray far-future rows land back inside the last six weeks */
UPDATE orders SET delivery_date = DATE_SUB(CURDATE(), INTERVAL (id % 40) DAY)
  WHERE delivery_date > DATE_ADD(CURDATE(), INTERVAL 45 DAY);
UPDATE orders SET created_at = DATE_SUB(delivery_date, INTERVAL 3 DAY)
  WHERE created_at > NOW();
UPDATE past_orders SET delivery_date = DATE_SUB(CURDATE(), INTERVAL 60 + (id % 90) DAY)
  WHERE delivery_date > CURDATE();
UPDATE past_orders SET created_at = DATE_SUB(delivery_date, INTERVAL 3 DAY)
  WHERE created_at > NOW();

UPDATE members SET
  created_at = DATE_ADD(created_at, INTERVAL 341 DAY),
  updated_at = DATE_ADD(updated_at, INTERVAL 341 DAY);
UPDATE members SET created_at = DATE_SUB(NOW(), INTERVAL (id % 300) DAY) WHERE created_at > NOW();

UPDATE invoices SET
  created_at = DATE_ADD(created_at, INTERVAL 369 DAY),
  updated_at = DATE_ADD(updated_at, INTERVAL 369 DAY);
UPDATE invoices SET created_at = DATE_SUB(NOW(), INTERVAL (id % 60) DAY) WHERE created_at > NOW();
