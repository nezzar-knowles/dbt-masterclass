with orders as (

    select * from {{ ref('stg_thelook__orders') }}

),

pivoted as (

    select
        order_id,
        user_id,
        order_status,
        gender,
        num_of_item,
        created_at,
        shipped_at,
        delivered_at,
        returned_at,

        -- Date-diff logic lives here once, instead of being recalculated
        -- in every downstream model that needs it. All three diffs are
        -- conditionally null because shipped_at/delivered_at/returned_at
        -- are themselves null until that lifecycle stage actually happens.
        {{ days_between('created_at', 'shipped_at') }}  as days_to_ship,
        {{ days_between('shipped_at', 'delivered_at') }} as days_to_deliver,
        {{ days_between('created_at', 'delivered_at') }} as days_to_fulfill,

        case when returned_at is not null then true else false end as was_returned

    from orders

)

select * from pivoted
