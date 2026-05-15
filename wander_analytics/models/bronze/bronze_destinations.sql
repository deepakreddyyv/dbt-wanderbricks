{{
    config(
        materialized= 'table',
        on_schema_change= 'fail'    
    )
}}


select
    {{ dbt_utils.generate_surrogate_key(['destination_id']) }} as destination_id_sk,
    *,
    current_timestamp() as elt_load_time

from {{ source('wander_analytics', 'src_destinations') }} as s



