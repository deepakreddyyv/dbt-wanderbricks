
{{
    config(
        materialized= 'incremental',
        unique_key= 'hosts_id_sk',
        incremental_strategy= 'append',
        on_schema_change= 'fail',
        schema='bronze',
        alias='bronze_hosts'
    )
}}

select
    {{ dbt_utils.generate_surrogate_key(['host_id']) }} as host_id_sk,
    *,
    current_timestamp() as elt_load_time

from {{ source('wander_analytics', 'src_hosts') }}

where 1=1 

{% if is_incremental() -%}
 and joined_at > ( select max(joined_at) from {{ this }} )
{%- endif %}

{% if target.name == 'dev' -%}
 and joined_at between '2023-07-01' and '2023-07-08 18:00:00'
{%- endif -%}
