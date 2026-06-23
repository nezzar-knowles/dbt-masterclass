-- Singular test — fails if it returns any rows.
--
-- A negative item_margin means an item sold below cost. This CAN be
-- legitimate (loss-leader pricing, clearance), so treat a failure here as
-- "go look at these rows," not necessarily "something is broken." Worth
-- discussing with students as an example of a test that's about visibility,
-- not pass/fail correctness.

select *
from {{ ref('fct_order_items') }}
where item_margin < 0
