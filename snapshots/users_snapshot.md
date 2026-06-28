

# YAML-based snapshot config (the current recommended syntax as of dbt
# v1.9+ / Latest release track — replaces the older {% snapshot %} Jinja
# block syntax you'll see in a lot of existing tutorials). If your project
# is on an older release track and this errors, the legacy equivalent is:
#
#   {% snapshot users_snapshot %}
#   {{ config(
#       target_schema='snapshots',
#       unique_key='id',
#       strategy='check',
#       check_cols=['street_address','postal_code','city','state','traffic_source']
#   ) }}
#   select * from {{ source('thelook_ecommerce', 'users') }}
#   {% endsnapshot %}
#
# WHY `check` AND NOT `timestamp`:
# The source `users` table has no updated_at column, so the timestamp
# strategy isn't available here — `check` is the only option, and it's
# also the right one for this table since it doesn't rely on the source
# reliably stamping every change.
#
# AN OPEN QUESTION, FLAGGED RATHER THAN ASSUMED:
# This snapshot demonstrates the correct mechanics regardless, but whether
# you'll actually SEE a row change (a populated dbt_valid_to) depends on
# whether Google's synthetic data generator ever mutates an existing user
# row in place, versus only ever appending new users. I don't know which
# of those is true. To find out: run `dbt snapshot` today, then again in
# a week or two, and check whether any dbt_valid_to is non-null. If it
# never changes, say so plainly to students rather than implying the
# dataset is doing something it might not be.

snapshots:
  - name: users_snapshot
    relation: source('thelook_ecommerce', 'users')
    config:
      schema: snapshots
      unique_key: id
      strategy: check
      check_cols:
        - street_address
        - postal_code
        - city
        - state
        - traffic_source