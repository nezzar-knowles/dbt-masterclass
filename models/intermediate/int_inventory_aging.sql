with inventory_resolved as (

    select * from {{ ref('int_inventory_resolved') }}

),

aging as (

    select
        inventory_item_id,
        product_id,
        product_name,
        category,
        department,
        inventory_unit_cost,
        retail_price,
        created_at,
        sold_at,
        is_currently_in_stock,

        -- Null for sold items by design — aging only matters for stock
        -- that's still sitting unsold. current_date() is evaluated at
        -- query/build time, so this number moves every run for unsold
        -- items, which is expected.
        case
            when is_currently_in_stock
                then {{ days_between('date(created_at)', 'current_date()') }}
            else null
        end as days_in_inventory

    from inventory_resolved

)

select * from aging