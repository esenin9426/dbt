with source as (

    select * from {{ ref('raw_orders') }}

),

renamed as (

    select
        order_id,
        customer_id,
        order_date,
        status

    from source

)

select * from renamed
