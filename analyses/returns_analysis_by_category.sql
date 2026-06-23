-- BUSINESS QUESTION: What's actually driving our return rate? A flat
-- "X% of orders returned" number is useless for action — this breaks
-- return rate down by category so a merchandising team can act on it.

select
    product_category,
    product_brand,
    count(*)                                       as total_items_sold,
    countif(order_status = 'returned')              as returned_items,
    {{ safe_divide_pct("countif(order_status = 'returned')", 'count(*)') }} as return_rate_pct,
    sum(case when order_status = 'returned' then sale_price else 0 end) as revenue_lost_to_returns

from {{ ref('fct_order_items') }}
group by product_category, product_brand
having count(*) >= 10  -- excludes categories/brands too small to draw conclusions from
order by return_rate_pct desc
