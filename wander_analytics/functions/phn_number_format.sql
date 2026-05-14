
  SELECT CASE
    WHEN REGEXP_EXTRACT(
           REGEXP_REPLACE(
             REGEXP_REPLACE(phone_number, '[^0-9]', ''),
             '^1([0-9]{10})$', '$1'
           ),
           '^([2-9]\\d{2})(\\d{3})(\\d{4})$', 1
         ) != ''
    THEN CONCAT(
      '(',
      REGEXP_EXTRACT(REGEXP_REPLACE(REGEXP_REPLACE(phone_number, '[^0-9]', ''), '^1([0-9]{10})$', '$1'), '^([2-9]\\d{2})(\\d{3})(\\d{4})$', 1),
      ') ',
      REGEXP_EXTRACT(REGEXP_REPLACE(REGEXP_REPLACE(phone_number, '[^0-9]', ''), '^1([0-9]{10})$', '$1'), '^([2-9]\\d{2})(\\d{3})(\\d{4})$', 2),
      '-',
      REGEXP_EXTRACT(REGEXP_REPLACE(REGEXP_REPLACE(phone_number, '[^0-9]', ''), '^1([0-9]{10})$', '$1'), '^([2-9]\\d{2})(\\d{3})(\\d{4})$', 3)
    )
    ELSE NULL
  END
