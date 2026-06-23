-- BUSINESS QUESTION: Are some distribution centers slower to ship/deliver
-- than others? This joins order-level fulfillment timing back to the DC
-- that fulfilled each line item — note an order can span multiple DCs if
-- its items come from different warehouses, so this is intentionally at
-- the order_item grain, not the order grain.

select
    items.distribution_center_name,
    count(*)                                as items_shipped,
    avg({{ days_between('items.created_at', 'items.shipped_at') }})   as avg_days_to_ship,
    avg({{ days_between('items.shipped_at', 'items.delivered_at') }}) as avg_days_in_transit,
    countif(items.order_status = 'returned')                  as returned_item_count,
    {{ safe_divide_pct("countif(items.order_status = 'returned')", 'count(*)') }} as return_rate_pct

from {{ ref('fct_order_items') }} as items
where items.distribution_center_name is not null
group by items.distribution_center_name
order by avg_days_to_ship desc
