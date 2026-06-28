with order_items_joined as (

    select * from {{ ref('int_order_items_joined') }}

),

distribution_centers as (

    select * from {{ ref('stg_thelook__distribution_centers') }}

),

joined as (

    select
        order_items_joined.*,
        distribution_centers.distribution_center_name,
        distribution_centers.latitude   as distribution_center_latitude,
        distribution_centers.longitude  as distribution_center_longitude

    from order_items_joined
    left join distribution_centers
        on order_items_joined.distribution_center_id = distribution_centers.distribution_center_id

)

select * from joined