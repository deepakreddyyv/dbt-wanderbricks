{{
    config(
        materialized='ephemeral'
    )
}}

select 
    p.property_id_sk,
    p.host_id_sk,
    p.destination_id_sk,
    p.property_id,
    p.host_id,
    p.destination_id,
    p.title,
    p.description,
    p.base_price,
    p.property_type,
    p.max_guests,
    p.bathrooms,
    p.bedrooms,
    p.property_latitude,
    p.property_longitude,
    p.created_at,
    p.elt_load_time
from {{ ref('bronze_properties') }} as p
qualify row_number() over (partition by property_id_sk order by created_at desc) = 1