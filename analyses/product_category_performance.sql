-- BUSINESS QUESTION: Which product categories drive the most revenue, and
-- which have the healthiest margin? High revenue and high margin don't
-- always come from the same category — this surfaces both side by side.

select
    product_category,
    product_department,
    count(distinct product_id)      as distinct_products_sold,
    count(*)                         as units_sold,
    sum(sale_price)                  as total_revenue,
    sum(item_margin)                 as total_margin,
    {{ safe_divide_pct('sum(item_margin)', 'sum(sale_price)') }} as margin_pct

from {{ ref('fct_order_items') }}
where order_status not in ('cancelled', 'returned')
group by product_category, product_department
order by total_revenue desc
