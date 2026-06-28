-- BUSINESS QUESTION: What's sitting unsold the longest, and how much
-- capital is tied up in it? Useful for a markdown/clearance conversation.

select
    category,
    department,
    count(*)                              as units_unsold,
    sum(inventory_unit_cost)               as capital_tied_up,
    avg(days_in_inventory)                 as avg_days_unsold,
    max(days_in_inventory)                 as oldest_unit_days_unsold

from {{ ref('fct_inventory') }}
where is_currently_in_stock
group by category, department
order by capital_tied_up desc