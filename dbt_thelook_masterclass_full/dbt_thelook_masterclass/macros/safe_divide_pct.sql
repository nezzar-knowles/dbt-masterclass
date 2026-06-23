{#
    safe_divide_pct(numerator, denominator)

    Wraps BigQuery's safe_divide() (returns null instead of erroring on a
    divide-by-zero) and multiplies by 100, so every margin/conversion-rate
    calculation in the project produces a percentage the same way instead
    of each model reinventing safe_divide(...) * 100 by hand.

    Usage:
        {{ safe_divide_pct('returned_items', 'total_items_sold') }} as return_rate_pct
#}
{% macro safe_divide_pct(numerator, denominator) %}
    safe_divide({{ numerator }}, {{ denominator }}) * 100
{% endmacro %}
