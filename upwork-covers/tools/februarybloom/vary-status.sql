SET SQL_SAFE_UPDATES=0;

/* Everything sat on "On the Way"; give the board the spread a real day has. */

-- past deliveries: mostly closed off
UPDATE orders SET order_status_id = ELT(1 + (id % 10), 32,32,32,4,32,32,4,34,32,33)
  WHERE delivery_date < CURDATE();

-- today: work in progress
UPDATE orders SET order_status_id = ELT(1 + (id % 8), 1,2,3,32,24,3,2,1)
  WHERE delivery_date = CURDATE();

-- upcoming: not started yet
UPDATE orders SET order_status_id = ELT(1 + (id % 6), 1,27,1,2,27,1)
  WHERE delivery_date > CURDATE();

-- payment state, shown in the Warehouse badge column
UPDATE orders SET secondary_status_id = ELT(1 + (id % 8), 28,28,28,27,28,26,28,25);

-- priority flags so the dashboard's priority tiles are not all zero
UPDATE orders SET priority = ELT(1 + (id % 10), 0,0,0,1,0,2,0,1,0,0)
  WHERE delivery_date BETWEEN CURDATE() - INTERVAL 3 DAY AND CURDATE() + INTERVAL 7 DAY;
