-- Business questions this answers: How much stock do we have sitting
-- unsold, and for how long? Which categories have the slowest-moving
-- inventory? What's our tied-up inventory cost?

with inventory_aging as (

    select * from {{ ref('int_inventory_aging') }}

)

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
    days_in_inventory

from inventory_aging