-- Business questions this answers: How much revenue per order? How fast do
-- we ship/deliver? What's our return rate? Does ordering on a holiday
-- correlate with anything? What channel/session preceded the order?

with orders as (

    select * from {{ ref('stg_thelook__orders') }}

),

order_items as (

    select * from {{ ref('stg_thelook__order_items') }}

),

pivoted_dates as (

    select * from {{ ref('int_orders_pivoted_status_dates') }}

),

holiday_flag as (

    select * from {{ ref('int_orders_with_holiday_flag') }}

),

attribution as (

    select * from {{ ref('int_events_to_orders_attribution') }}

),

order_revenue as (

    select
        order_id,
        sum(sale_price)         as order_revenue,
        count(*)                as line_item_count,
        countif(order_status = 'returned' or order_status = 'cancelled') as returned_or_cancelled_item_count

    from order_items
    group by order_id

),

final as (

    select
        orders.order_id,
        orders.user_id,
        orders.order_status,
        orders.gender,
        orders.num_of_item,
        orders.created_at,

        coalesce(order_revenue.order_revenue, 0)         as order_revenue,
        coalesce(order_revenue.line_item_count, 0)        as line_item_count,
        coalesce(order_revenue.returned_or_cancelled_item_count, 0) as returned_or_cancelled_item_count,

        pivoted_dates.days_to_ship,
        pivoted_dates.days_to_deliver,
        pivoted_dates.days_to_fulfill,
        pivoted_dates.was_returned,

        holiday_flag.holiday_name,
        holiday_flag.is_major_shopping_holiday,
        holiday_flag.placed_on_holiday,

        -- Heuristic, not verified — see int_events_to_orders_attribution
        -- in-file comment before relying on this for real decisions.
        attribution.attributed_traffic_source,
        attribution.attributed_session_id

    from orders
    left join order_revenue
        on orders.order_id = order_revenue.order_id
    left join pivoted_dates
        on orders.order_id = pivoted_dates.order_id
    left join holiday_flag
        on orders.order_id = holiday_flag.order_id
    left join attribution
        on orders.order_id = attribution.order_id

)

select * from final