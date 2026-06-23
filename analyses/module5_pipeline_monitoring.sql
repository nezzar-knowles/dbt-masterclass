-- ============================================================
-- MODULE 5: Pipeline Monitoring Queries
-- ============================================================
-- These queries run AGAINST YOUR OWN MARTS (not the thelook source)
-- to verify pipeline health after each scheduled run. In a real
-- production setup these would feed a monitoring dashboard or
-- trigger alerts. For the course, run them manually after each
-- dbt run to show students what "did my job actually work" looks
-- like beyond just "the dbt run logs say green."
-- ============================================================

-- 1. ROW COUNT SANITY CHECK
-- Run this after every production job and compare to yesterday.
-- An order_item_count that drops significantly (not just flattens)
-- suggests something broke upstream in the source data.
-- An order_item_count that never grows suggests the incremental
-- model's filter is broken or the source stopped updating.

select
    date(created_at)   as order_date,
    count(*)            as order_item_count,
    sum(sale_price)     as daily_revenue,
    count(distinct order_id) as order_count

from {{ ref('fct_order_items') }}
where date(created_at) >= date_sub(current_date(), interval 14 day)
group by order_date
order by order_date desc;


-- 2. INCREMENTAL MODEL HEALTH CHECK
-- Specific to fct_order_items_incremental — verifies the 3-day
-- lookback buffer is actually picking up late-arriving status
-- changes (e.g. rows that moved from 'shipped' to 'returned'
-- within the buffer window). If returned_items_last_3_days is
-- always zero, the buffer is not doing anything useful.

select
    date(created_at)                        as order_date,
    countif(order_status = 'returned')       as returned_items,
    countif(order_status = 'shipped')        as shipped_items,
    countif(order_status = 'complete')       as completed_items

from {{ ref('fct_order_items_incremental') }}
where date(created_at) >= date_sub(current_date(), interval 7 day)
group by order_date
order by order_date desc;


-- 3. SNAPSHOT HEALTH CHECK
-- Verifies the users_snapshot has been running and capturing
-- changes. The active_user_count should equal the row count in
-- stg_thelook__users. If dbt_valid_to starts populating on any
-- rows, that's confirmation the source is actually mutating
-- existing user records (see Module 3 snapshot caveat).

select
    count(*)                                   as total_snapshot_rows,
    countif(dbt_valid_to is null)               as active_user_count,
    countif(dbt_valid_to is not null)            as historical_user_count,
    max(dbt_updated_at)                          as most_recent_snapshot_run

from {{ ref('users_snapshot') }};


-- 4. TEST RESULT PROXY
-- dbt's own test results live in the run logs, not the warehouse.
-- This query is a lightweight proxy that surfaces the conditions
-- your key singular tests check for, so you can see at a glance
-- whether the data would pass or fail them — useful as a "show
-- students what tests are actually checking" explainer.

select
    'negative_margins'          as check_name,
    count(*)                     as failing_rows,
    'assert_no_negative_margins' as source_test
from {{ ref('fct_order_items') }}
where item_margin < 0

union all

select
    'impossible_lifecycle_dates',
    count(*),
    'assert_order_item_dates_in_order'
from {{ ref('fct_order_items') }}
where (shipped_at is not null and shipped_at < created_at)
   or (delivered_at is not null and delivered_at < shipped_at)

union all

select
    'inventory_sold_before_created',
    count(*),
    'assert_inventory_item_not_sold_before_created'
from {{ ref('fct_inventory') }}
where sold_at is not null and sold_at < created_at

order by failing_rows desc;
