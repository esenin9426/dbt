-- Singular-тест: падает, если fct_orders.amount не равен сумме собственных
-- колонок по способам оплаты. Хороший пример проверки бизнес-правила,
-- которое не укладывается в generic-тест уровня колонки. См. guide/06-testing.

select
    order_id,
    amount,
    credit_card_amount + coupon_amount + bank_transfer_amount + gift_card_amount as recomputed_amount
from {{ ref('fct_orders') }}
where amount != credit_card_amount + coupon_amount + bank_transfer_amount + gift_card_amount
