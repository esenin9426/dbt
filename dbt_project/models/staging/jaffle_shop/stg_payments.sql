with source as (

    select * from {{ ref('raw_payments') }}

),

renamed as (

    select
        payment_id,
        order_id,
        payment_method,

        -- в исходной системе `amount` хранится в центах; здесь переводим
        -- в доллары, чтобы все последующие модели работали в удобной единице.
        {{ cents_to_dollars('amount') }} as amount

    from source

)

select * from renamed
