{#
    days_between(start_date, end_date)

    Wraps BigQuery's date_diff(..., day), with arguments in the more
    intuitive start-then-end order (BigQuery's native date_diff actually
    takes end-then-start as its first two arguments, which trips people up
    constantly). Centralizes the date-diff pattern already repeated across
    int_orders_pivoted_status_dates, int_users_first_order_attribution, and
    int_inventory_aging — if the project ever needs to switch warehouses
    (BigQuery's date_diff syntax differs from Snowflake's DATEDIFF), this
    is the one place that needs to change.

    Note the argument order matches how you'd say it in English ("days
    between X and Y"), not BigQuery's native order — that's the whole
    point of wrapping it.

    Usage:
        {{ days_between('created_at', 'shipped_at') }} as days_to_ship
#}
{% macro days_between(start_date, end_date) %}
    date_diff({{ end_date }}, {{ start_date }}, day)
{% endmacro %}
