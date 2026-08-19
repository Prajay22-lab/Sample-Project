{{ config(materialized='view') }}

-- combines each account with its opportunity(ies), one row per account/opportunity pair

select
    a.account_id,
    a.customer_id,
    a.account_name,
    a.account_type,
    a.industry,
    a.annual_revenue,
    o.opportunity_id,
    o.opportunity_name,
    o.stage,
    o.amount,
    o.close_date,
    case
        when o.stage = 'CLOSED WON' then 'WON'
        when o.stage = 'CLOSED LOST' then 'LOST'
        else 'OPEN'
    end as opportunity_status,
    {{ opportunity_amount_category('amount') }}
    as opportunity_amount_category
from {{ ref('stg_accounts') }} a
left join {{ ref('stg_opportunities') }} o
    on a.account_id = o.account_id
