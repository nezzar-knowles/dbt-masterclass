-- Singular test — fails if it returns any rows.
--
-- This duplicates what the `relationships` generic test on
-- stg_thelook__order_items.order_id already checks. It's included here
-- specifically as a teaching example — written out by hand so students
-- can see exactly what a `relationships` test is doing under the hood,
-- rather than treating it as a black box. In a real project you would NOT
-- keep both the generic test and this singular test long-term, since
-- they're redundant.

select order_items.*
from {{ ref('fct_order_items') }} as order_items
left join {{ ref('fct_orders') }} as orders
    on order_items.order_id = orders.order_id
where orders.order_id is null
