---
name: dbt-architect
description: Design dbt projects, models, tests, and architectures. Also use to review dbt code quality or conventions.
metadata:
  stage: Concept
  capability: dbt Architecture
  practices:
    - de
  tags:
    - dbt
  scope: pro
---

# dbt Architecture Skill

## Project Structure

Enforce this directory structure for all dbt projects:

```
models/
├── staging/                    # 1:1 with source tables
│   └── <source_name>/
│       ├── _<source>__models.yml
│       ├── _<source>__sources.yml
│       └── stg_<source>__<table>.sql
├── intermediate/               # Business logic layer
│   └── <domain>/
│       └── int_<entity>__<verb>.sql
└── marts/                      # Business-facing outputs
    └── <department>/
        ├── _<dept>__models.yml
        ├── fct_<noun>.sql
        └── dim_<noun>.sql
```

## Naming Conventions

| Layer | Pattern | Example |
|-------|---------|---------|
| Staging | `stg_<source>__<table>` | `stg_stripe__payments` |
| Intermediate | `int_<entity>__<verb>` | `int_orders__pivoted` |
| Fact | `fct_<noun>` | `fct_orders` |
| Dimension | `dim_<noun>` | `dim_customers` |

## Model Templates

### Staging Model

```sql
-- models/staging/<source>/stg_<source>__<table>.sql
with source as (
    select * from {{ source('<source>', '<table>') }}
),

renamed as (
    select
        -- Primary key
        id as <entity>_id,
        
        -- Foreign keys
        foreign_id as related_entity_id,
        
        -- Properties (rename to business terms)
        amount_cents / 100.0 as amount,
        
        -- Timestamps (always cast explicitly)
        created_at::timestamp as created_at,
        updated_at::timestamp as updated_at
        
    from source
)

select * from renamed
```

### Intermediate Model

```sql
-- models/intermediate/<domain>/int_<entity>__<verb>.sql
with <entity1> as (
    select * from {{ ref('stg_<source>__<table1>') }}
),

<entity2> as (
    select * from {{ ref('stg_<source>__<table2>') }}
),

joined as (
    select
        <entity1>.<pk>,
        <entity1>.field1,
        <entity2>.field2
    from <entity1>
    left join <entity2> 
        on <entity1>.fk = <entity2>.pk
)

select * from joined
```

### Mart Model (Fact)

```sql
-- models/marts/<dept>/fct_<noun>.sql
{{
    config(
        materialized='incremental',
        unique_key='<pk>',
        on_schema_change='sync_all_columns'
    )
}}

with <source_cte> as (
    select * from {{ ref('int_<entity>__<verb>') }}
    {% if is_incremental() %}
    where updated_at > (select max(updated_at) from {{ this }})
    {% endif %}
),

final as (
    select
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key(['field1', 'field2']) }} as <entity>_sk,
        
        -- Natural key
        <entity>_id,
        
        -- Foreign keys
        customer_id,
        product_id,
        
        -- Facts (measures)
        quantity,
        amount,
        
        -- Timestamps
        created_at,
        updated_at
        
    from <source_cte>
)

select * from final
```

## Schema YAML Template

```yaml
# models/staging/<source>/_<source>__models.yml
version: 2

models:
  - name: stg_<source>__<table>
    description: >
      Staging model for <table> from <source>.
      One row per <grain>.
    
    columns:
      - name: <entity>_id
        description: Primary key
        tests:
          - unique
          - not_null
      
      - name: <fk>_id
        description: Foreign key to <related_entity>
        tests:
          - relationships:
              to: ref('stg_<source>__<related_table>')
              field: <related_entity>_id
```

## Required Tests

Every model MUST have these tests configured:

| Column Type | Required Tests |
|-------------|----------------|
| Primary key | `unique`, `not_null` |
| Foreign key | `relationships` |
| Status/enum | `accepted_values` |
| Required field | `not_null` |

## Materialization Guidelines

| Model Type | Materialization | When |
|------------|-----------------|------|
| Staging | `view` | Default for all staging |
| Staging | `ephemeral` | Only used by one downstream model |
| Intermediate | `ephemeral` | Default |
| Intermediate | `view` | Debugging or reused heavily |
| Mart | `table` | <1M rows, full refresh acceptable |
| Mart | `incremental` | >1M rows or expensive transforms |

## Anti-Patterns (Never Do)

- ❌ Business logic in staging models
- ❌ Joins in staging models
- ❌ Exposing intermediate models to BI tools
- ❌ Using `{{ this }}` without incremental config
- ❌ Hardcoded database/schema names
- ❌ `select *` in final select (always explicit columns)
- ❌ Missing primary key tests
- ❌ Chained ephemeral models (>2 deep)
- ❌ Complex logic in config blocks

## Incremental Best Practices

```sql
-- Always include these configs for incremental
{{
    config(
        materialized='incremental',
        unique_key='<pk>',              -- Required: dedupe key
        on_schema_change='sync_all_columns',  -- Handle schema drift
        incremental_strategy='merge'    -- Or 'delete+insert' for Snowflake
    )
}}

-- Always filter with is_incremental()
{% if is_incremental() %}
where updated_at > (select max(updated_at) from {{ this }})
{% endif %}
```

## Macro Usage

Prefer `dbt_utils` macros for common patterns:

```sql
-- Surrogate keys
{{ dbt_utils.generate_surrogate_key(['col1', 'col2']) }}

-- Pivot
{{ dbt_utils.pivot('column', values) }}

-- Date spine
{{ dbt_utils.date_spine(start_date, end_date) }}

-- Star schema joins
{{ dbt_utils.star(from=ref('model'), relation_alias='alias') }}
```

