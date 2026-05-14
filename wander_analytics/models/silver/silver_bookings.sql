
{{
    config(
        materialized= 'ephemeral',
    )
}}

select 
    b.booking_id_sk,
    b.user_id_sk,
    b.property_id_sk,
    b.check_in,
    b.check_out,
    b.guests_count,
    b.total_amount,
    b.status,
    b.created_at,
    b.updated_at,
    b.elt_load_time
from {{ ref('bronze_bookings') }} as b
qualify row_number() over (partition by booking_id_sk order by updated_at desc) = 1