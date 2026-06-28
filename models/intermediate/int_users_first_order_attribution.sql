with users as (

    select * from {{ ref('stg_thelook__users') }}

),

user_rollup as (

    select * from {{ ref('int_users_order_history_rollup') }}

),

first_order_attribution as (

    select
        users.user_id,
        users.traffic_source       as acquisition_channel,
        users.created_at           as signup_at,
        user_rollup.first_order_at,
        user_rollup.lifetime_order_count,
        user_rollup.lifetime_revenue,

        -- Days between signup and first purchase. Null if the user has
        -- never ordered (first_order_at will be null from the left join).
        {{ days_between('users.created_at', 'user_rollup.first_order_at') }} as days_to_first_order,

        case when user_rollup.first_order_at is not null then true else false end as has_ordered

    from users
    left join user_rollup
        on users.user_id = user_rollup.user_id

)

select * from first_order_attribution