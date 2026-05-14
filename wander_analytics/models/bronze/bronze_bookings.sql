
{{
    config(
        materialized= 'incremental',
        unique_key= 'booking_id_sk',
        incremental_strategy= 'append',
        on_schema_change= 'fail'
    )
}}

select
    {{ dbt_utils.generate_surrogate_key(['booking_id']) }} as booking_id_sk,
    {{ dbt_utils.generate_surrogate_key(['user_id']) }} as user_id_sk,
    {{ dbt_utils.generate_surrogate_key(['property_id']) }} as property_id_sk,
    *,
    current_timestamp() as elt_load_time

from {{ source('wander_analytics', 'src_bookings') }}

where 1=1 

{% if is_incremental() -%}
 and created_at > ( select max(created_at) from {{ this }} )
{%- endif %}

{% if target.name == 'dev' -%}
 and created_at between '2023-07-01' and '2023-07-08 18:00:00'
{%- endif -%}
