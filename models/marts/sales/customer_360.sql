{{ config(materialized='table') }}

-- consolidated customer-level reporting mart: one row per customer.
-- accounts and opportunities are each aggregated to customer_id
-- BEFORE joining to dim_customer, so the join cannot fan out.

with account_agg as (

    select
        customer_id,
        count(distinct account_id) as total_accounts
    from {{ ref('dim_account') }}
    group by customer_id

),

opportunity_agg as (

    select
        customer_id,
        count(distinct opportunity_id) as total_opportunities,
        sum(opportunity_amount) as total_opportunity_amount,
        count(distinct case when opportunity_status = 'WON' then opportunity_id end) as won_opportunity_count,
        count(distinct case when opportunity_status = 'LOST' then opportunity_id end) as lost_opportunity_count,
        count(distinct case when opportunity_status = 'OPEN' then opportunity_id end) as open_opportunity_count,
        sum(case when opportunity_status = 'WON' then opportunity_amount else 0 end) as total_won_amount,
        sum(case when opportunity_status = 'OPEN' then opportunity_amount else 0 end) as total_open_amount
    from {{ ref('fct_opportunity') }}
    group by customer_id

)

select
    c.customer_sk,
    c.customer_id,
    c.customer_name,
    c.email,
    c.country,
    c.customer_status,
    coalesce(a.total_accounts, 0) as total_accounts,
    coalesce(o.total_opportunities, 0) as total_opportunities,
    coalesce(o.total_opportunity_amount, 0) as total_opportunity_amount,
    coalesce(o.won_opportunity_count, 0) as won_opportunity_count,
    coalesce(o.lost_opportunity_count, 0) as lost_opportunity_count,
    coalesce(o.open_opportunity_count, 0) as open_opportunity_count,
    coalesce(o.total_won_amount, 0) as total_won_amount,
    coalesce(o.total_open_amount, 0) as total_open_amount
from {{ ref('dim_customer') }} c
left join account_agg a
    on c.customer_id = a.customer_id
left join opportunity_agg o
    on c.customer_id = o.customer_id
