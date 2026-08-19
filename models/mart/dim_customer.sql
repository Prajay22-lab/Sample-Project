{{ config(materialized='table') }}

-- customer dimension: one row per customer, with account count rolled up
-- from int_customer_accounts (customer/account grain)

with customer_accounts as (

    select
        customer_id,
        customer_name,
        email,
        country,
        customer_status,
        account_id
    from {{ ref('int_customer_accounts') }}

),

customer_attributes as (

    select distinct
        customer_id,
        customer_name,
        email,
        {{ clean_text('country') }} as country,
        customer_status
    from customer_accounts

),

account_counts as (

    select
        customer_id,
        count(distinct account_id) as account_count
    from customer_accounts
    where account_id is not null
    group by customer_id

)

select
    md5(cast(ca.customer_id as varchar)) as customer_sk,
    ca.customer_id,
    ca.customer_name,
    ca.email,
    ca.country,
    ca.customer_status,
    coalesce(ac.account_count, 0) as account_count
from customer_attributes ca
left join account_counts ac
    on ca.customer_id = ac.customer_id
