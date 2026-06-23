{#
    standardize_text()

    Trims and lowercases a free-text categorical column (status, event_type,
    traffic_source, etc.). Several public write-ups of this dataset filter
    on mixed casing (e.g. comparing against 'Complete' in one place and
    'complete' in another) — that's a sign the casing isn't guaranteed
    consistent. Standardizing once here, in staging, means every downstream
    model and every accepted_values test only has to deal with one casing
    convention instead of guessing per-query.

    Usage:
        {{ standardize_text('status') }} as order_status
#}
{% macro standardize_text(column_name) %}
    trim(lower({{ column_name }}))
{% endmacro %}
