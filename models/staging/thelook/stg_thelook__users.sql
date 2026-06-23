with source as (

    select * from {{ source('thelook_ecommerce', 'users') }}

),

renamed as (

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
        {{ standardize_text('traffic_source') }} as traffic_source,
        created_at

    from source

)

select * from renamed
