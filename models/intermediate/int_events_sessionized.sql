with events as (

    select * from {{ ref('stg_thelook__events') }}

),

session_events as (

    select
        session_id,
        user_id,
        min(created_at)  as session_started_at,
        max(created_at)  as session_ended_at,
        count(*)         as event_count,
        countif(event_type = 'purchase')   as purchase_event_count,
        -- entry uri: the row with the lowest sequence_number in the session
        array_agg(uri order by sequence_number asc limit 1)[offset(0)]  as entry_uri,
        array_agg(traffic_source order by sequence_number asc limit 1)[offset(0)] as traffic_source,
        array_agg(browser order by sequence_number asc limit 1)[offset(0)] as browser

    from events
    group by session_id, user_id

),

sessionized as (

    select
        *,
        date_diff(session_ended_at, session_started_at, second) as session_duration_seconds,
        case when purchase_event_count > 0 then true else false end as converted_in_session

    from session_events

)

select * from sessionized
