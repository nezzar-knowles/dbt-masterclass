-- Singular test — fails if it returns any rows.
--
-- fct_orders.order_revenue is calculated independently from
-- fct_order_items.sale_price (both ultimately come from the same source
-- table, but through two different aggregation paths). If either model
-- changes independently, they could silently drift apart. This test
-- catches that by recomputing the line-item sum directly and comparing.

with order_level as (

    select order_id, order_revenue
    from {{ ref('fct_orders') }}

),

line_item_level as (

    select order_id, sum(sale_price) as line_item_revenue
    from {{ ref('fct_order_items') }}
    group by order_id

),

compared as (

    select
        order_level.order_id,
        order_level.order_revenue,
        line_item_level.line_item_revenue
    from order_level
    left join line_item_level
        on order_level.order_id = line_item_level.order_id
    where round(order_level.order_revenue, 2) != round(coalesce(line_item_level.line_item_revenue, 0), 2)

)

select * from compared
