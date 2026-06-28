-- Singular test — fails if it returns any rows.
--
-- sold_at earlier than created_at would mean genuinely broken source
-- data, not just a modeling choice — there's no legitimate business
-- reason for an inventory unit to sell before it existed in the system.

select *
from {{ ref('fct_inventory') }}
where sold_at is not null
  and sold_at < created_at