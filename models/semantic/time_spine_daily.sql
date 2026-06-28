{{
    config(
        materialized='table'
    )
}}

-- This model is REQUIRED by MetricFlow. Without it, dbt parse throws:
-- "The semantic layer requires a time spine model with granularity DAY
-- or smaller in the project, but none was found."
--
-- What it does: generates one row per day across a date range.
-- MetricFlow uses this as the date scaffold for all time-based metric
-- aggregations (monthly revenue, trailing 30 day windows, running
-- totals, etc.). Without it, none of the time dimensions or
-- cumulative metrics in the semantic layer can be queried.
--
-- dbt.date_spine() is a cross-adapter macro from dbt-core that
-- generates a series of dates at a given granularity. On BigQuery it
-- compiles to a GENERATE_DATE_ARRAY or recursive CTE depending on the
-- adapter version -- you don't need to write that SQL yourself.

with base_dates as (
    {{
        dbt.date_spine(
            'day',
            "date('2020-01-01')",
            "date('2030-01-01')"
        )
    }}
),

final as (
    select cast(date_day as date) as date_day
    from base_dates
)

select *
from final
-- Keep 5 years back and 1 year forward from today.
-- The thelook_ecommerce dataset currently runs from roughly 2019
-- onward, but the 2020 start date above covers the bulk of useful
-- history while keeping the table small. Adjust if you need to
-- query metrics before 2020.
where date_day >= date_sub(current_date(), interval 5 year)
  and date_day <= date_add(current_date(), interval 365 day)
