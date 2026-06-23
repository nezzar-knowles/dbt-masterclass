-- BUSINESS QUESTION: How is revenue trending month over month, and what's
-- happening to average order value alongside it? A revenue number alone
-- can hide whether growth is coming from more orders or bigger orders.

select
    date_trunc(date(created_at), month) as order_month,
    count(distinct order_id)            as order_count,
    sum(order_revenue)                  as total_revenue,
    safe_divide(sum(order_revenue), count(distinct order_id)) as avg_order_value

from {{ ref('fct_orders') }}
group by order_month
order by order_month
