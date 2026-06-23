-- Business questions this answers: What's our product catalog? What's our
-- markup by category/brand/department? Which distribution center stocks
-- a given product?

with products as (

    select * from {{ ref('stg_thelook__products') }}

),

distribution_centers as (

    select * from {{ ref('stg_thelook__distribution_centers') }}

),

final as (

    select
        products.product_id,
        products.product_name,
        products.brand,
        products.category,
        products.department,
        products.sku,
        products.cost,
        products.retail_price,
        products.retail_price - products.cost as expected_margin,
        -- Now expressed 0-100 (a true percentage) via safe_divide_pct,
        -- not 0-1 like the original safe_divide(...) version. If any
        -- downstream model/dashboard was built against the old 0-1 scale,
        -- it needs updating alongside this change.
        {{ safe_divide_pct('products.retail_price - products.cost', 'products.retail_price') }} as expected_margin_pct,
        products.distribution_center_id,
        distribution_centers.distribution_center_name

    from products
    left join distribution_centers
        on products.distribution_center_id = distribution_centers.distribution_center_id

)

select * from final
