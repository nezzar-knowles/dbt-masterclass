with source as (

    select * from {{ source('thelook_ecommerce', 'users') }}

),

traffic_source as (
    select * from {{ref('traffic_source_channel_mapping')}}
),

enriched as (

    select
        id                  as user_id,
        first_name,
        last_name,
        email,
        age,
        gender,
        state,
        street_address,
        postal_code,
        city,
        country,
        latitude,
        longitude,
        {{ standardize_text('s.traffic_source') }} as traffic_source,
        channel_group,
        created_at

    from source as s
    left join traffic_source as ts
    on s.traffic_source = ts.traffic_source

)

select * from enriched