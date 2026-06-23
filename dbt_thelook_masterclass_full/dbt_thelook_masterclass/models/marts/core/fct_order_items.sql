-- Business questions this answers: What's our margin by product/category/
-- brand? Which products sell best? Which distribution center fulfills the
-- most revenue? (This is the grain almost every revenue and margin
-- question should start from — order-level revenue undercounts when an
-- order has multiple line items with different products.)

with order_items_joined as (

    select * from {{ ref('int_order_items_with_distribution_center') }}

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
