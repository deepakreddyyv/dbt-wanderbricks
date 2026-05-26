{{
    config(
        materialized='view',
        schema='gold',
        tags=['dimension_modelling', 'star_schema']
    )
}}

select 
    *
from {{ ref('silver_properties') }}