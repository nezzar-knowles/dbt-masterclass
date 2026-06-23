-- BUSINESS QUESTION: Which acquisition channel actually converts and
-- drives revenue, not just traffic volume? Sessions and revenue come from
-- two different marts here on purpose — fct_sessions captures all
-- browsing behavior, while the revenue figure comes from dim_customers'
-- lifetime_revenue keyed off each customer's original acquisition_channel.
-- These are two different (legitimate) ways to cut "channel performance"
-- and will not match exactly — worth discussing with students why.

with channel_traffic as (

    select
        traffic_source,
        count(*)                       as session_count,
        countif(converted_in_session)   as converted_sessions,
        {{ safe_divide_pct('countif(converted_in_session)', 'count(*)') }} as session_conversion_rate_pct

    from {{ ref('fct_sessions') }}
    group by traffic_source

),

channel_revenue as (

    select
        acquisition_channel as traffic_source,
        count(*)             as customers_acquired,
        sum(lifetime_revenue) as total_revenue_from_channel

    from {{ ref('dim_customers') }}
    group by acquisition_channel

)

select
    coalesce(channel_traffic.traffic_source, channel_revenue.traffic_source) as traffic_source,
    channel_traffic.session_count,
    channel_traffic.session_conversion_rate_pct,
    channel_revenue.customers_acquired,
    channel_revenue.total_revenue_from_channel

from channel_traffic
full outer join channel_revenue
    on channel_traffic.traffic_source = channel_revenue.traffic_source
order by total_revenue_from_channel desc
