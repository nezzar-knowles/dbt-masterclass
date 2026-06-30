{{
    config(
        tags = ['customer']
    )
}}


-- Business questions this answers: Who are our customers? How much have
-- they spent? Where did they come from? How long until they first bought?
-- Are they a repeat customer? What's their nearest fulfillment location?

with users as (

    select * from {{ ref('stg_thelook__users') }}

),

order_history as (

    select * from {{ ref('int_users_order_history_rollup') }}

),

first_order_attribution as (

    select * from {{ ref('int_users_first_order_attribution') }}

),

nearest_dc as (

    select * from {{ ref('int_users_nearest_distribution_center') }}

),

final as (

    select
        users.user_id,
        users.first_name,
        users.last_name,
        users.email,
        users.age,
        users.gender,
        users.city,
        users.state,
        users.country,
        users.traffic_source       as acquisition_channel,
        users.created_at           as signup_at,

        coalesce(order_history.lifetime_order_count, 0) as lifetime_order_count,
        coalesce(order_history.lifetime_revenue, 0)      as lifetime_revenue,
        order_history.first_order_at,
        order_history.most_recent_order_at,

        first_order_attribution.has_ordered,
        first_order_attribution.days_to_first_order,

        case
            when coalesce(order_history.lifetime_order_count, 0) = 0 then 'never_purchased'
            when order_history.lifetime_order_count = 1 then 'one_time_customer'
            else 'repeat_customer'
        end as customer_segment,

        nearest_dc.nearest_distribution_center_id,
        nearest_dc.nearest_distribution_center_name,
        nearest_dc.distance_to_nearest_dc_km

    from users
    left join order_history
        on users.user_id = order_history.user_id
    left join first_order_attribution
        on users.user_id = first_order_attribution.user_id
    left join nearest_dc
        on users.user_id = nearest_dc.user_id

)

select * from final