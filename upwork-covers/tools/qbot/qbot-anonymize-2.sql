SET SQL_SAFE_UPDATES=0;

/* turnstile access logs carry a visitor name, card number and device serial */
UPDATE access_logs SET
  person_name = CONCAT('Visitor ', access_log_id),
  card_no  = IF(card_no IS NULL OR card_no='', card_no, LPAD((access_log_id * 7919) % 1000000000, 10, '0')),
  person_sn = IF(person_sn IS NULL OR person_sn='', person_sn, CONCAT('SN', LPAD(access_log_id, 8, '0')));

UPDATE user_registrations SET
  name = CONCAT('Registration ', user_registration_id),
  card_number = IF(card_number IS NULL OR card_number='', card_number, LPAD((user_registration_id * 7919) % 1000000000, 10, '0'));

/* customer-written review text */
UPDATE feedback SET
  feedback = IF(feedback IS NULL OR feedback='', feedback, ELT(1 + (id % 4),
    'Queue moved quickly and the staff were helpful.','Rides were clean, food court was busy at lunch.',
    'Booking online was easy, entry scan worked first try.','Good value for a family day out.')),
  improvement_suggestion = IF(improvement_suggestion IS NULL OR improvement_suggestion='', improvement_suggestion,
    ELT(1 + (id % 3),'More shaded seating near the wave pool.','Longer opening hours on weekends.','Clearer signage to the lockers.'));

UPDATE insight SET
  additional_feedback = IF(additional_feedback IS NULL OR additional_feedback='', additional_feedback,
    ELT(1 + (id % 3),'Enjoyed the visit, will come again.','Staff handled the queue well.','Food options could be wider.'));

UPDATE devices SET communication_password = NULL;
