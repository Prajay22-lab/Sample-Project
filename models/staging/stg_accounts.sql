select
    account_id,
    customer_id,
    upper(trim(account_name)) as account_name,
    upper(trim(account_type)) as account_type,
    upper(trim(industry)) as industry,
    annual_revenue,
    created_date,
    updated_date
from {{ source('salesforce', 'accounts') }}
