-- BUSINESS QUESTION: Do major shopping holidays (Black Friday, Cyber
-- Monday, etc.) actually produce an order-volume lift in this dataset?
-- This directly exercises the holiday_calendar seed from Module 3 and
-- int_orders_with_holiday_flag from the intermediate layer.

select
    is_major_shopping_holiday,
    holiday_name,
    count(distinct order_id)  as order_count,
    sum(order_revenue)         as total_revenue,
    safe_divide(sum(order_revenue), count(distinct order_id)) as avg_order_value

from {{ ref('fct_orders') }}
where placed_on_holiday
group by is_major_shopping_holiday, holiday_name
order by total_revenue desc
