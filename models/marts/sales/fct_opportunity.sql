{{
    config(
        materialized='incremental',
        unique_key='opportunity_id',
        on_schema_change='sync_all_columns',
        incremental_strategy='merge'
    )
}}

-- opportunity fact: one row per opportunity, sourced from
-- int_customers__joined_opportunities (already at opportunity grain).
-- watermarked on updated_date rather than close_date, since an opportunity
-- can be revised (amount, stage) after its close_date without that date moving.

{% if is_incremental() and execute %}
  {% set target_columns = adapter.get_columns_in_relation(this) | map(attribute='name') | map('upper') | list %}
{% else %}
  {% set target_columns = [] %}
{% endif %}

with source_cte as (

    select * from {{ ref('int_customers__joined_opportunities') }}
    where opportunity_id is not null

    {% if is_incremental() and 'UPDATED_DATE' in target_columns %}
    -- alias + qualify to avoid Snowflake binding this max() to the
    -- CTE's own updated_date column instead of {{ this }}.
    -- Guarded on target_columns so a target table built before this
    -- column existed (e.g. a stale CI schema) falls back to a full
    -- backfill instead of erroring on a missing column.
    and updated_date > (select max(existing.updated_date) from {{ this }} as existing)
    {% endif %}

),

final as (

    select
        md5(cast(opportunity_id as varchar)) as opportunity_sk,
        opportunity_id,
        account_id,
        customer_id,
        opportunity_name,
        stage,
        opportunity_status,
        opportunity_amount,
        {{ opportunity_amount_category('opportunity_amount') }} as opportunity_amount_category,
        close_date,
        updated_date,
        case when opportunity_status = 'WON' then true else false end as is_won,
        case when opportunity_status = 'LOST' then true else false end as is_lost,
        case when opportunity_status = 'OPEN' then true else false end as is_open
    from source_cte

)

select * from final

