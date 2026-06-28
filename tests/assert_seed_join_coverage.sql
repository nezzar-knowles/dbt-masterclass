{{ config(severity='warn') }}

-- Singular test — fails if it returns any rows.
--
-- traffic_source_channel_mapping.csv was built from assumed values, not
-- verified against the live table (see its description in
-- seeds/_thelook__seeds.yml). An unmatched traffic_source value produces
-- a silent null channel_group rather than an error. This test turns that
-- risk into something dbt test actually catches: if more than 5% of users
-- fail to match the seed, something needs reconciling.
--
-- Returns one row (the unmatched percentage) only when it exceeds the
-- threshold — so a passing run returns zero rows, same as every other
-- singular test here.

with joined as (

    select
        users.user_id,
        users.traffic_source,
        mapping.traffic_source,
        mapping.channel_group
    from {{ ref('stg_thelook__users') }} as users
    left join {{ ref('traffic_source_channel_mapping') }} as mapping
        on users.traffic_source = mapping.traffic_source

),

coverage as (

    select
        countif(channel_group is null) as unmatched_count,
        count(*)                        as total_count,
        safe_divide(countif(channel_group is null), count(*)) as unmatched_pct
    from joined

)

select *
from coverage
where unmatched_pct > 0.05