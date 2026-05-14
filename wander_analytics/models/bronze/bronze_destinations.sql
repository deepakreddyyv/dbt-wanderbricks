{{
    config(
        materialized= 'table',
        unique_key= 'destination_id_sk',
        incremental_strategy= 'append',
        on_schema_change= 'fail'
    )
}}


select
    {{ dbt_utils.generate_surrogate_key(['destination_id']) }} as destination_id_sk,
    *,
    current_timestamp() as elt_load_time,
    current_timestamp() as updated_at

from {{ source('wander_analytics', 'src_destinations') }} as s


{% if is_incremental() -%}
    left join {{ this }} as t
    on s.destination_id = t.destination_id
    where t.destination_id is null
{%- endif %}

