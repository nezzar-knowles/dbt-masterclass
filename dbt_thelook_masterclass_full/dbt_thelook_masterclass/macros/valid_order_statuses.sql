{#
    valid_order_statuses()

    Single source of truth for the order lifecycle enum, reused by the
    accepted_values tests on both stg_thelook__orders.order_status and
    stg_thelook__order_items.order_status. Without this, the same list
    would need to be hand-copied into two places in the yml and would
    silently drift out of sync the next time someone adds a value.

    !! ACTION REQUIRED before relying on this in a real build !!
    The values below are my best assessment from secondary sources
    (blog posts/queries referencing 'Complete', 'Cancelled', 'Returned',
    plus the commonly cited 'Processing' and 'Shipped' lifecycle stages),
    standardized to lowercase to match standardize_text(). I have NOT
    verified this is the complete, current list against the live table.
    Run the two `select distinct status from ...` queries in
    analyses/peek_at_source_data.sql and edit this list to match exactly
    what comes back before you teach with it or rely on it for a passing
    test suite.
#}
{% macro valid_order_statuses() %}
    {{ return(['processing', 'shipped', 'complete', 'cancelled', 'returned']) }}
{% endmacro %}
