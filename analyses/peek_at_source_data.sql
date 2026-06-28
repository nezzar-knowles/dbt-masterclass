-- =============================================================================
-- PRE-FLIGHT CHECK: run each block below (via dbt compile, or paste straight
-- into the BigQuery console) BEFORE building any staging models.
--
-- This file lives in analyses/, not models/. That's deliberate and worth
-- calling out explicitly to students: models/ is for things that get built
-- into the warehouse every run. analyses/ is for one-off, exploratory SQL
-- that you want version-controlled and compiled with ref()/source() syntax,
-- but never materialized. If it doesn't need to run on a schedule, it
-- doesn't belong in models/.
-- =============================================================================
-- 1. Row counts per table — confirms scale before you pick materializations
-- or talk about incremental strategy in Module 4.
select 'users' as table_name, count(*) as row_count
from {{ source("thelook_ecommerce", "users") }}
union all
select 'orders', count(*)
from {{ source("thelook_ecommerce", "orders") }}
union all
select 'order_items', count(*)
from {{ source("thelook_ecommerce", "order_items") }}
union all
select 'products', count(*)
from {{ source("thelook_ecommerce", "products") }}
union all
select 'inventory_items', count(*)
from {{ source("thelook_ecommerce", "inventory_items") }}
union all
select 'distribution_centers', count(*)
from {{ source("thelook_ecommerce", "distribution_centers") }}
union all
select 'events', count(*)
from {{ source("thelook_ecommerce", "events") }}
;

-- 2. Real date range — don't quote a range from a blog post, this dataset
-- has reportedly kept growing over time.
select min(created_at) as earliest_order, max(created_at) as latest_order
from {{ source("thelook_ecommerce", "orders") }}
;

-- 3. Exact current enum values — confirm before you write any test or
-- teach students what to expect. Don't assume these from documentation.
select distinct status
from {{ source("thelook_ecommerce", "orders") }}
;
select distinct status
from {{ source("thelook_ecommerce", "order_items") }}
;
select distinct event_type
from {{ source("thelook_ecommerce", "events") }}
;
select distinct traffic_source
from {{ source("thelook_ecommerce", "users") }}
;

-- 4. Column list sanity check — confirm order_items actually has the
-- columns you expect (sale_price in particular — see project README).
select  column_name, data_type
from `bigquery-public-data.thelook_ecommerce.INFORMATION_SCHEMA.COLUMNS`
where table_name = 'order_items'
order by ordinal_position
;

-- 5. Partitioning/clustering check — affects how you teach incremental
-- models and query cost in Module 4.
select table_name, partition_column_name, clustering_columns
from `bigquery-public-data.thelook_ecommerce.INFORMATION_SCHEMA.PARTITIONS`
limit 1
;