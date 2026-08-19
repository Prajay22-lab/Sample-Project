{{ config(materialized='view') }}

-- active customers left-joined to their opportunities, one row per
-- active customer/opportunity pair (mirrors the legacy Spark filter -> join).
-- opportunities link to customers via accounts (account_id -> customer_id),
-- not directly by customer_id, so the join goes through stg_accounts.

select
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    c.customer_status,
    o.opportunity_id,
    o.stage,
    o.amount
from {{ ref('stg_customers') }} c
left join {{ ref('stg_accounts') }} a
    on c.customer_id = a.customer_id
left join {{ ref('stg_opportunities') }} o
    on a.account_id = o.account_id
where c.customer_status = 'ACTIVE'
