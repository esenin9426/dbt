with source as (

    select * from {{ source('raw', 'events') }}

),

renamed as (

    select
        event_id,
        customer_id,
        event_type,
        event_at,
        loaded_at

    from source

)

select * from renamed
