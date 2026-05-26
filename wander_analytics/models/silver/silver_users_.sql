{% set st_check_cols = ['email', 'name', 'country', 'user_type', 'is_business', 'company_name'] %}

{{
    config(
        materialized = 'incremental',
        unique_key = 'user_id_sk',
        incremental_strategy = 'merge',
        incremental_predicates = ["DBT_INTERNAL_DEST.is_active = true"],
        on_schema_change =' fail',
        alias = 'silver_users_scd1'
    )
}}

select 
    {% if is_incremental() %} 
        coalesce(s.user_id_sk, t.user_id_sk) as user_id_sk,
        coalesce(s.user_id, t.user_id) as user_id,
        coalesce(s.email, t.email, "{{ var('default_null_value_descriptive_name') }}") as email,
        coalesce(s.name, t.name) as name,
        coalesce(s.country, t.country) as country,
        coalesce(s.user_type, t.user_type) as user_type,
        coalesce(s.created_at, t.created_at) as created_at,
        coalesce(s.is_business, t.is_business) as is_business,
        coalesce(s.company_name, t.company_name, "{{ var('default_null_value_descriptive_name') }}") as company_name,
        coalesce(s.elt_load_time, t.elt_load_time) as elt_load_time,

        case 
            when s.user_id_sk is null then false 
            else true 
        end as is_active,
        
        case 
            when t.user_id_sk is not null 
            and {{ st_md5_check_cols(st_check_cols, 's', 't') }}
            then current_timestamp()
            else t.updated_at 
        end as updated_at
        

    {% else %}
        user_id_sk,
        user_id,
        coalesce(email, "{{ var('default_null_value_descriptive_name') }}") as email,
        name,
        country,
        user_type,
        created_at,
        is_business,
        coalesce(company_name, "{{ var('default_null_value_descriptive_name') }}") as company_name,
        elt_load_time,
        True as is_active,
        current_timestamp() as updated_at   
    {% endif %}
from {{ ref('bronze_users') }}  as s

{% if is_incremental() -%}
    full outer join {{ this }} as t
    on s.user_id_sk = t.user_id_sk
    where (t.is_active or t.is_active is null)
{%- endif %}

