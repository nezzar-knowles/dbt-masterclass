{#
    limit_in_dev(row_limit=1000)

    Returns a LIMIT clause only when running against the dev target — in
    prod (or any target whose name isn't 'dev'), it returns nothing, so
    the full table builds as normal. This is the standard pattern for
    iterating fast on a large source table (events is the obvious
    candidate in this project) without scanning/processing the whole thing
    on every single dbt run while developing.

    IMPORTANT: this checks target.name, which depends on what your dbt
    Cloud environment is actually named. dbt Cloud's default Development
    environment is typically named 'default' rather than literally 'dev' —
    check Deploy > Environments in your dbt Cloud project and adjust the
    string below to match if it doesn't trigger as expected.

    Usage, at the bottom of a staging model:
        select * from source
        {{ limit_in_dev() }}

        select * from source
        {{ limit_in_dev(row_limit=500) }}
#}
{% macro limit_in_dev(row_limit=1000) %}
    {% if target.name == 'dev' %}
        limit {{ row_limit }}
    {% endif %}
{% endmacro %}
