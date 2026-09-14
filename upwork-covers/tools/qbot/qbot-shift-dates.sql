SET SQL_SAFE_UPDATES=0;

/* +287d puts the busiest week (2025-11-26/27) on yesterday and today.
   Anything that lands in the future is pulled back into the last six weeks. */

UPDATE orders SET created_at = created_at + INTERVAL 287 DAY, updated_at = updated_at + INTERVAL 287 DAY;
UPDATE order_details SET created_at = created_at + INTERVAL 287 DAY, updated_at = updated_at + INTERVAL 287 DAY;
UPDATE order_histories SET created_at = created_at + INTERVAL 287 DAY, updated_at = updated_at + INTERVAL 287 DAY;
UPDATE general_transactions SET created_at = created_at + INTERVAL 287 DAY, updated_at = updated_at + INTERVAL 287 DAY;
UPDATE session_transactions SET created_at = created_at + INTERVAL 287 DAY, updated_at = updated_at + INTERVAL 287 DAY;
UPDATE pos_sessions SET created_at = created_at + INTERVAL 287 DAY, updated_at = updated_at + INTERVAL 287 DAY;
UPDATE carts SET created_at = created_at + INTERVAL 287 DAY, updated_at = updated_at + INTERVAL 287 DAY;
UPDATE customers SET created_at = created_at + INTERVAL 287 DAY, updated_at = updated_at + INTERVAL 287 DAY;
UPDATE bookings SET created_at = created_at + INTERVAL 287 DAY, updated_at = updated_at + INTERVAL 287 DAY;

UPDATE orders SET created_at = NOW() - INTERVAL (order_id % 42) DAY - INTERVAL (order_id % 600) MINUTE
  WHERE created_at > NOW();
UPDATE orders SET updated_at = created_at WHERE updated_at > NOW();
UPDATE order_details d JOIN orders o ON o.order_id = d.order_id
  SET d.created_at = o.created_at, d.updated_at = o.created_at WHERE d.created_at > NOW();
UPDATE order_histories h JOIN orders o ON o.order_id = h.order_id
  SET h.created_at = o.created_at, h.updated_at = o.created_at WHERE h.created_at > NOW();
UPDATE customers SET created_at = NOW() - INTERVAL (customer_id % 120) DAY WHERE created_at > NOW();
UPDATE carts SET created_at = NOW() - INTERVAL (cart_id % 30) DAY WHERE created_at > NOW();
UPDATE bookings SET created_at = NOW() - INTERVAL (booking_id % 20) DAY WHERE created_at > NOW();
UPDATE general_transactions SET created_at = NOW() - INTERVAL (id % 40) DAY WHERE created_at > NOW();
UPDATE session_transactions SET created_at = NOW() - INTERVAL (id % 40) DAY WHERE created_at > NOW();
UPDATE pos_sessions SET created_at = NOW() - INTERVAL (pos_session_id % 20) DAY WHERE created_at > NOW();
UPDATE bookings SET booking_date = DATE(created_at) + INTERVAL (booking_id % 7) DAY;
