{#
    not_in_future

    Custom generic test. Fails if any row has `column_name` later than the
    moment the test runs. Worth having specifically because we confirmed
    this dataset is live and updated through today's date rather than a
    frozen historical snapshot — a future-dated created_at would be a real
    data quality signal, not a quirk of stale documentation.

    Usage in a .yml file:
        columns:
          - name: created_at
            tests:
              - not_in_future
#}
{% test not_in_future(model, column_name) %}

select *
from {{ model }}
where {{ column_name }} > current_timestamp()

{% endtest %}
