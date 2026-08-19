{% macro opportunity_amount_category(amount) %}
    case
        when {{ amount }} < 250000 then 'SMALL'
        when {{ amount }} >= 250000 and {{ amount }} < 500000 then 'MEDIUM'
        when {{ amount }} >= 500000 then 'LARGE'
    end
{% endmacro %}
