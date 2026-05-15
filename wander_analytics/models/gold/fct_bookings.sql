{{
    config(
        materialized='table',
        schema='gold'
    )
}}

select
    a.booking_id_sk,
    a.user_id_sk,
    a.property_id_sk,
    c.host_id_sk,
    d.destination_id_sk,
    a.check_in,
    a.check_out,
    a.guests_count,
    b.base_price,
    a.total_amount,
    a.status,
    a.created_at,
    a.updated_at,
    a.elt_load_time
    
from {{ ref('silver_bookings_scd2') }} a
left join {{ ref('silver_properties_scd2') }} b
on a.property_id_sk = b.property_id_sk and b.record_end_date is null
left join {{ ref('silver_hosts_scd2') }} c
on b.host_id_sk = c.host_id_sk and c.record_end_date is null
left join {{ ref('silver_destinations') }} d
on b.destination_id_sk = d.destination_id_sk
where a.record_end_date is null