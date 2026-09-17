-- Analyses компилируются командой `dbt compile`, но никогда не строятся
-- в хранилище. Удобно для разового / исследовательского SQL, который
-- хочется хранить в git с доступом к ref()/source(). См. guide/13-advanced-topics.

select
    customer_id,
    first_name,
    last_name
from {{ ref('dim_customers') }}
where number_of_orders = 0
