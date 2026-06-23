with orders as (

    select * from {{ ref('stg_thelook__orders') }}

),

holiday_calendar as (

    select * from {{ ref('holiday_calendar') }}

),

orders_with_holiday as (

    select
        orders.order_id,
        orders.user_id,
        orders.order_status,
        orders.created_at,
        date(orders.created_at)            as order_date,
        holiday_calendar.holiday_name,
        holiday_calendar.is_major_shopping_holiday,
        case when holiday_calendar.holiday_date is not null then true else false end as placed_on_holiday

    from orders
    left join holiday_calendar
        on date(orders.created_at) = holiday_calendar.holiday_date

)

select * from orders_with_holiday
