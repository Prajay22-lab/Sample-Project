select
    opportunity_id,
    account_id,
    upper(trim(opportunity_name)) as opportunity_name,
    upper(trim(stage)) as stage,
    amount,
    close_date,
    created_date,
    updated_date
from {{ source('salesforce', 'opportunities') }}
