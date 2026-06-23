with users as (

    select * from {{ ref('stg_thelook__users') }}

),

distribution_centers as (

    select * from {{ ref('stg_thelook__distribution_centers') }}

),

-- Cross join is intentional and necessary here: to find the NEAREST
-- distribution center, every user has to be compared against every
-- distribution center, then ranked. distribution_centers is a tiny table
-- (a handful of rows), so this cross join is cheap despite the word
-- "cross join" sounding alarming — it's bounded by distribution center
-- count, not by users squared.
distances as (

    select
        users.user_id,
        distribution_centers.distribution_center_id,
        distribution_centers.distribution_center_name,
        -- ST_DISTANCE returns meters on BigQuery's GEOGRAPHY type, which
        -- already accounts for earth curvature (no manual haversine
        -- formula needed) — divide by 1000 for kilometers.
        st_distance(
            st_geogpoint(users.longitude, users.latitude),
            st_geogpoint(distribution_centers.longitude, distribution_centers.latitude)
        ) / 1000 as distance_km

    from users
    cross join distribution_centers
    where users.latitude is not null
      and users.longitude is not null

),

ranked as (

    select
        *,
        row_number() over (partition by user_id order by distance_km asc) as proximity_rank

    from distances

)

select
    user_id,
    distribution_center_id  as nearest_distribution_center_id,
    distribution_center_name as nearest_distribution_center_name,
    distance_km              as distance_to_nearest_dc_km

from ranked
where proximity_rank = 1
