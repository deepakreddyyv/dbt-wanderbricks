
select 
    *
    except (scd_id)
from {{ ref('silver_users_scd2') }}


{%- if model.name in var('gold_scd1_enabled_views', [] ) -%}

{{ log("model name: " ~ model.name ~ " is in scd1_enabled_tables : " ~ var('gold_scd1_enabled_views', []), info=true) }}

where end_date is null

{% endif -%}
