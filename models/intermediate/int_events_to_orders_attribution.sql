with orders as (

    select * from {{ ref('stg_thelook__orders') }}

),

sessions as (

    select * from {{ ref('int_events_sessionized') }}

),

-- IMPORTANT, READ BEFORE USING THIS MODEL:
-- events and orders share only user_id — there is no direct foreign key
-- between a specific order and a specific session. This model attributes
-- each order to the most recent session by the same user that started
-- BEFORE the order was placed, within a 24-hour lookback window. That is
-- a reasonable, defensible heuristic, but it is still a heuristic, not a
-- verified fact. A user could browse on their phone and order from their
-- laptop in a way that breaks this logic entirely, and there's no way to
-- detect that from this data. Use this model to teach attribution
-- modeling concepts and present results with that caveat attached — don't
-- present "session converted" rates from this model as ground truth.
candidate_sessions as (

    select
        orders.order_id,
        orders.user_id,
        orders.created_at as order_created_at,
        sessions.session_id,
        sessions.session_started_at,
        sessions.traffic_source,
        row_number() over (
            partition by orders.order_id
            order by sessions.session_started_at desc
        ) as session_recency_rank

    from orders
    left join sessions
        on orders.user_id = sessions.user_id
        and sessions.session_started_at <= orders.created_at
        and sessions.session_started_at >= timestamp_sub(orders.created_at, interval 24 hour)

),

attributed as (

    select
        order_id,
        user_id,
        order_created_at,
        session_id          as attributed_session_id,
        session_started_at  as attributed_session_started_at,
        traffic_source       as attributed_traffic_source

    from candidate_sessions
    where session_recency_rank = 1
       or session_id is null   -- preserves orders with no matching session at all

)

select * from attributed