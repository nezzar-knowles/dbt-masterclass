with source as (

    select * from {{ source('thelook_ecommerce', 'inventory_items') }}

),

renamed as (

    select
        id                              as inventory_item_id,
        product_id,
        cost,
        created_at,
        sold_at,
        -- These product_* columns duplicate stg_thelook__products and are
        -- kept here only because they exist on the source table as-is.
        -- See the inventory_items_product_duplication doc block — the
        -- intermediate layer should decide whether to keep these or join
        -- to stg_thelook__products instead, not both.
        product_category                as inv_product_category,
        product_name                    as inv_product_name,
        product_brand                   as inv_product_brand,
        product_retail_price            as inv_product_retail_price,
        product_department              as inv_product_department,
        product_sku                     as inv_product_sku,
        product_distribution_center_id  as inv_product_distribution_center_id

    from source

)

select * from renamed
