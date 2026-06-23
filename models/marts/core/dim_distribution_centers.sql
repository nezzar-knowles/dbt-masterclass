-- Business question this answers: How many distribution centers do we have,
-- and where are they? (Deliberately thin — most of the analytical value of
-- distribution centers comes through fct_order_items and dim_customers'
-- nearest-DC fields, not from this dimension alone.)

with distribution_centers as (

    select * from {{ ref('stg_thelook__distribution_centers') }}

)

select * from distribution_centers
