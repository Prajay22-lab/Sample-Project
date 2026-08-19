{{ config(materialized='incremental', unique_key='opportunity_id') }}

-- opportunity fact: one row per opportunity, sourced from
-- int_customer_opportunities (already at opportunity grain)

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
    case when opportunity_status = 'WON' then true else false end as is_won,
    case when opportunity_status = 'LOST' then true else false end as is_lost,
    case when opportunity_status = 'OPEN' then true else false end as is_open
from {{ ref('int_customer_opportunities') }}
where opportunity_id is not null

{% if is_incremental() %}
  and close_date > (select max(close_date) from {{ this }})
{% endif %}
