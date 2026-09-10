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

with source_cte as (

    select * from {{ ref('int_customers__joined_opportunities') }}
    where opportunity_id is not null

    {% if is_incremental() %}
    -- alias + qualify to avoid Snowflake binding this max() to the
    -- CTE's own updated_date column instead of {{ this }}
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

