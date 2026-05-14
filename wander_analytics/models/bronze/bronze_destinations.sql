{{
    config(
        materialized= 'table'
    )
}}


select
    {{ dbt_utils.generate_surrogate_key(['destination_id']) }} as destination_id_sk,
    *,
    current_timestamp() as elt_load_time,
    current_timestamp() as updated_at

from {{ source('wander_analytics', 'src_destinations') }} as s



