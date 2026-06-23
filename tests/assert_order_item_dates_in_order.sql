-- Singular test — fails if it returns any rows.
--
-- created_at <= shipped_at <= delivered_at whenever each is non-null.
-- Catches impossible lifecycle sequences (e.g. delivered before shipped),
-- which would indicate a real data quality problem upstream rather than
-- anything wrong with our modeling.

select *
from {{ ref('fct_order_items') }}
where (shipped_at is not null and shipped_at < created_at)
   or (delivered_at is not null and shipped_at is not null and delivered_at < shipped_at)
   or (delivered_at is not null and delivered_at < created_at)
