{% snapshot snp_customers %}

{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='updated_date',
    )
}}

select
    customer_id,
    first_name,
    last_name,
    email,
    country,
    customer_status,
    created_date,
    updated_date
from {{ ref('stg_customers') }}

{% endsnapshot %}
