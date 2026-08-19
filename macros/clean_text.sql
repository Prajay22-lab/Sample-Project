{% macro clean_text(column) %}
    upper(trim({{ column }}))
{% endmacro %}
