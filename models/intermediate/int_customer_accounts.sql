{{ config(materialized='view') }}

-- combines each customer with their account(s), one row per customer/account pair

select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.country,
    c.customer_status,
    c.first_name || ' ' || c.last_name as customer_name,
    a.account_id,
    a.account_name,
    a.account_type,
    a.industry,
    a.annual_revenue
from {{ ref('stg_customers') }} c
left join {{ ref('stg_accounts') }} a
    on c.customer_id = a.customer_id
