with source as (

    select * from {{ source('thelook_ecommerce', 'events') }}

),

renamed as (

    select
        id                  as event_id,
        user_id,
        session_id,
        sequence_number,
        {{ standardize_text('event_type') }}   as event_type,
        {{ standardize_text('traffic_source') }} as traffic_source,
        browser,
        uri,
        ip_address,
        city,
        state,
        postal_code,
        created_at

    from source

)

select * from renamed