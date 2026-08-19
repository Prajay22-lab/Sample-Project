{{ config(materialized='table') }}

-- customer pipeline summary: one row per active customer, with opportunity
-- volume and won/open amounts, migrated from the legacy Spark aggregation.
-- "won" = stage 'CLOSED WON'; "open" = any non-closed stage (no closed-lost),
-- since the source data has granular stages rather than a single literal
-- 'Open' stage as in the legacy system.

select
    customer_id,
    customer_name,
    count(opportunity_id) as opportunity_count,
    sum(case when stage = 'CLOSED WON' then amount else 0 end) as won_amount,
    sum(case when stage not in ('CLOSED WON', 'CLOSED LOST') then amount else 0 end) as open_amount
from {{ ref('int_active_customer_opportunities') }}
group by customer_id, customer_name
