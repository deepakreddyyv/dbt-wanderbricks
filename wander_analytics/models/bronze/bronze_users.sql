
select
    {{ dbt_utils.generate_surrogate_key(['user_id']) }} as user_id_sk,
    *,
    current_timestamp() as elt_load_time

from {{ source('wander_analytics', 'src_users') }}

where 1=1 

{% if is_incremental() -%}
 and created_at > ( select max(created_at) from {{ this }} )
{%- endif %}

{% if target.name == 'dev' -%}
 and created_at between '2023-07-01' and '2023-07-08 18:00:00'
{%- endif -%}
