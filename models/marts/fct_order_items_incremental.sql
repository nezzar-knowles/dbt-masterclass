{{
    config(
        tags = ['order_item']
    )
}}

-- BigQuery-specific: partition by the order date so each daily
-- incremental run only scans the latest partition, not the whole
-- table. Without this, every run scans the full fct_order_items
-- history even though it only adds a small slice of new rows.
    {{
    config(
        materialized='incremental',
        unique_key='order_item_id',
        on_schema_change='sync_all_columns',
        partition_by={
            "field": "created_at",
            "data_type": "timestamp",
            "granularity": "day"
        },
        cluster_by=["product_category", "order_status"]
    )
}}

-- ============================================================
-- WHY THIS IS THE RIGHT MODEL TO MAKE INCREMENTAL
-- ============================================================
-- fct_order_items is by far the largest mart model (fct_sessions/
-- inventory_items are bigger at the source, but fct_order_items is
-- the one BI tools will query most often). Once order_items has enough
-- history, rebuilding it from scratch on every scheduled run wastes
-- compute and time. The incremental pattern here: on the first run
-- it builds everything, on every subsequent run it only processes
-- rows newer than the most recent row already in the table.
--
-- The unique_key='order_item_id' means if a row is reprocessed (e.g.
-- because an order_item's status changed from 'shipped' to 'returned')
-- it MERGES rather than duplicates. This is critical for this dataset
-- because order lifecycle status changes AFTER the initial order is
-- placed -- a naive append-only incremental would leave stale 'shipped'
-- rows sitting alongside updated 'returned' rows.
-- ============================================================

with order_items_joined as (

    select * from {{ ref('int_order_items_with_distribution_center') }}

    {% if is_incremental() %}
    -- On incremental runs: only process rows created or updated since
    -- the most recent row already in the table, minus a 3-day lookback
    -- buffer. The buffer exists because order status can change for
    -- several days after an order is placed (shipped → delivered →
    -- returned), and we want to reprocess those rows to pick up the
    -- updated status rather than leaving the old value frozen in the table.
    where created_at >= (
        select timestamp_sub(max(created_at), interval 3 day)
        from {{ this }}
    )
    {% endif %}

)

select
    order_item_id,
    order_id,
    user_id,
    product_id,
    inventory_item_id,
    order_status,
    sale_price,
    product_cost,
    product_category,
    product_department,
    product_brand,
    item_margin,
    distribution_center_id,
    distribution_center_name,
    created_at,
    shipped_at,
    delivered_at,
    returned_at

from order_items_joined

