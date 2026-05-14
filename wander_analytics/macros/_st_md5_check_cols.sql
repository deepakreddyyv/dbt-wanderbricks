{% macro st_md5_check_cols(check_cols, s_alias='s', t_alias='t') %}
    md5(concat(
        {% for col in check_cols %} 
            coalesce({{ s_alias }}.{{ col }}, '') 
        {% if not loop.last %}, 
        {% endif %}
        {% endfor %})) != md5(concat(
            {% for col in check_cols %} 
                coalesce({{ t_alias }}.{{ col }}, '') 
            {% if not loop.last %}, 
            {% endif %}
            {% endfor %}))
    {{ log("Generated md5 check condition for columns: " ~ check_cols, info=true) }}
{% endmacro %}