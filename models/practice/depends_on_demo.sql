{{ config(materialized='view') }}

-- depends_on: {{ ref('dim_customer') }}

select
    current_timestamp() as execution_time,
    'depends_on_demo' as model_name
