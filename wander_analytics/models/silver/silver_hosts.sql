{{
    config(
        materialized= 'ephemeral'
    )
}}

select 
    h.host_id_sk,
    h.host_id,
    h.name,
    h.email,
    {{ function('phn_number_format') }}(h.phone) as phone,
    h.is_verified,
    h.is_active,
    h.rating,
    h.country,
    h.joined_at,
    h.elt_load_time
from {{ ref('bronze_hosts') }} as h
where is_active
qualify row_number() over (partition by host_id_sk order by elt_load_time desc) = 1