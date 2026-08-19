{{ config(materialized='table') }}

-- account dimension: one row per account, sourced from int_customer_accounts
-- (customer/account grain, already one row per account) to avoid fan-out
-- from the account/opportunity join in int_account_opportunities

with account_base as (

    select distinct
        account_id,
        customer_id,
        account_name,
        account_type,
        industry,
        annual_revenue
    from {{ ref('int_customer_accounts') }}
    where account_id is not null

)

select
    md5(cast(account_id as varchar)) as account_sk,
    account_id,
    customer_id,
    account_name,
    account_type,
    industry,
    annual_revenue
from account_base
