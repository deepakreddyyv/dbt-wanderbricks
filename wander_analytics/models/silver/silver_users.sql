
{{
    config(
        materialized= 'ephemeral'
    )
}}

select 
    user_id_sk,
    user_id,
    coalesce(email, "{{ var('default_null_value_descriptive_name') }}") as email,
    name,
    country,
    user_type,
    is_business,
    coalesce(company_name, "{{ var('default_null_value_descriptive_name') }}") as company_name,
    created_at,
    elt_load_time 
from {{ ref('bronze_users') }}
qualify row_number() over (partition by user_id_sk order by created_at desc) = 1