
{% set st_check_cols = ['description'] %}

{{
    config(
        materialized= 'incremental',
        unique_key= 'destination_id_sk',
        incremental_strategy= 'merge',
        merge_update_columns= ['description', 'updated_at'],
        on_schema_change= 'fail'
    )
}}

select 
    s.*,
{% if is_incremental() %}
    case 
        when {{ st_md5_check_cols(st_check_cols, 's', 't') }} then current_timestamp()
        else t.updated_at
    end as updated_at
{% else %}
    current_timestamp() as updated_at
{% endif %}

from {{ ref('bronze_destinations') }} as s

{% if is_incremental() %}
    left join {{ this }} as t
    on s.destination_id_sk = t.destination_id_sk
{% endif %}