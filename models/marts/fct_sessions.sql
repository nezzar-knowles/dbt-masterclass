{{
    config(
        tags = ['session']
    )
}}

-- Business questions this answers: How much traffic do we get by channel?
-- What's our session-to-purchase conversion rate? How long are sessions?
-- This table is intentionally independent of orders/revenue — join to
-- int_events_to_orders_attribution (or fct_orders.attributed_session_id)
-- only when you specifically need to connect a session to a dollar amount,
-- and remember that link is a heuristic, not a guarantee.

with sessionized as (

    select * from {{ ref('int_events_sessionized') }}

)

select
    session_id,
    user_id,
    session_started_at,
    session_ended_at,
    session_duration_seconds,
    event_count,
    purchase_event_count,
    converted_in_session,
    entry_uri,
    traffic_source,
    browser

from sessionized