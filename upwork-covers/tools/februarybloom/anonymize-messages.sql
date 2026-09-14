/* Gift-card text and delivery instructions are customer-written; replace them. */
SET SQL_SAFE_UPDATES=0;

UPDATE order_details SET
  message = IF(message IS NULL OR message='', message, ELT(1+(id%8),
    'Happy Birthday! Wishing you a wonderful year ahead.',
    'Congratulations on the new home.',
    'Thinking of you today.',
    'With deepest sympathy.',
    'Happy Anniversary - here is to many more.',
    'Get well soon.',
    'Thank you for everything.',
    'Congratulations on your graduation!')),
  special_message = IF(special_message IS NULL OR special_message='', special_message, ELT(1+(id%6),
    'Please call the recipient before arrival.',
    'Leave at the guardhouse if nobody answers.',
    'Deliver to the office reception, level 12.',
    'Do not ring the doorbell, baby sleeping.',
    'Surprise delivery - do not mention the sender.',
    'Please deliver after 2pm.'));

UPDATE past_order_details SET
  message = IF(message IS NULL OR message='', message, ELT(1+(id%8),
    'Happy Birthday! Wishing you a wonderful year ahead.',
    'Congratulations on the new home.',
    'Thinking of you today.',
    'With deepest sympathy.',
    'Happy Anniversary - here is to many more.',
    'Get well soon.',
    'Thank you for everything.',
    'Congratulations on your graduation!')),
  special_message = IF(special_message IS NULL OR special_message='', special_message, ELT(1+(id%6),
    'Please call the recipient before arrival.',
    'Leave at the guardhouse if nobody answers.',
    'Deliver to the office reception, level 12.',
    'Do not ring the doorbell, baby sleeping.',
    'Surprise delivery - do not mention the sender.',
    'Please deliver after 2pm.'));
