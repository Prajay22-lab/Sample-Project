{{ config(materialized='view') }}

-- builds a customer-level opportunity dataset at opportunity grain,
-- adding account-level and customer-level opportunity totals via window functions

select
    ca.customer_id,
    ca.customer_name,
    ca.email,
    ca.country,
    ca.customer_status,
    ca.account_id,
    ca.account_name,
    ca.account_type,
    ca.industry,
    ao.opportunity_id,
    ao.opportunity_name,
    ao.stage,
    ao.amount as opportunity_amount,
    ao.close_date,
    ao.opportunity_status,
    ao.opportunity_amount_category,
    sum(ao.amount) over (partition by ca.account_id) as total_account_opportunity_amount,
    count(ao.opportunity_id) over (partition by ca.customer_id) as customer_opportunity_count,
    sum(ao.amount) over (partition by ca.customer_id) as customer_total_opportunity_amount
from {{ ref('int_customer_accounts') }} ca
left join {{ ref('int_account_opportunities') }} ao
    on ca.account_id = ao.account_id
