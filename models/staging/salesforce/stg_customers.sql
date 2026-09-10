select
    customer_id,
    upper(trim(first_name)) as first_name,
    upper(trim(last_name)) as last_name,
    lower(trim(email)) as email,
    trim(country) as country,
    {{ clean_text('customer_status') }} as customer_status,
    created_date,
    updated_date
from {{ source('salesforce', 'customers') }}
