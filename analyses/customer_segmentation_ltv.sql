-- BUSINESS QUESTION: How many of our customers actually come back to buy
-- again, and how much more are they worth than one-time buyers? This is
-- the kind of question that justifies retention spend.

select
    customer_segment,
    acquisition_channel,
    count(*)                                   as customer_count,
    sum(lifetime_revenue)                       as segment_total_revenue,
    safe_divide(sum(lifetime_revenue), count(*)) as avg_lifetime_revenue,
    avg(lifetime_order_count)                    as avg_order_count

from {{ ref('dim_customers') }}
group by customer_segment, acquisition_channel
order by segment_total_revenue desc