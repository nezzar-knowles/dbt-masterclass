with order_items as (

    select * from {{ ref('stg_thelook__order_items') }}

),

products as (

    select * from {{ ref('stg_thelook__products') }}

),

joined as (

    select
        order_items.order_item_id,
        order_items.order_id,
        order_items.user_id,
        order_items.product_id,
        order_items.inventory_item_id,
        order_items.order_status,
        order_items.sale_price,
        products.cost                  as product_cost,
        products.category              as product_category,
        products.department            as product_department,
        products.brand                 as product_brand,
        products.distribution_center_id,
        order_items.sale_price - products.cost as item_margin,
        order_items.created_at,
        order_items.shipped_at,
        order_items.delivered_at,
        order_items.returned_at

    from order_items
    left join products
        on order_items.product_id = products.product_id

)

select * from joined
