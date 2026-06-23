with inventory_items as (

    select * from {{ ref('stg_thelook__inventory_items') }}

),

products as (

    select * from {{ ref('stg_thelook__products') }}

),

resolved as (

    -- DECISION: stg_thelook__products is treated as the source of truth
    -- for product attributes, not the inv_product_* columns carried on
    -- inventory_items. Rationale: products is the catalog system of
    -- record; inventory_items' copies are a snapshot of attributes at the
    -- time the inventory unit was created and can drift out of date if a
    -- product's price or category changes later. If you ever need to see
    -- what a product looked like AT THE TIME a unit was stocked (e.g. for
    -- historical cost-of-goods accuracy), use the raw inv_product_* columns
    -- on stg_thelook__inventory_items directly instead of this model.
    select
        inventory_items.inventory_item_id,
        inventory_items.product_id,
        inventory_items.cost           as inventory_unit_cost,
        inventory_items.created_at,
        inventory_items.sold_at,
        products.product_name,
        products.brand,
        products.category,
        products.department,
        products.sku,
        products.retail_price,
        products.distribution_center_id,
        case when inventory_items.sold_at is null then true else false end as is_currently_in_stock

    from inventory_items
    left join products
        on inventory_items.product_id = products.product_id

)

select * from resolved
