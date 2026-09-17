# 06 — Тестирование

## Цель

Разобраться в трёх видах тестов dbt, используемых в этом проекте, и
добавить по одному тесту каждого вида самостоятельно.

## Теория

| Вид | Где живёт | К чему применяется | Пример в этом репозитории |
|---|---|---|---|
| **Generic (встроенный)** | `data_tests:` под колонкой в `.yml` | Любая колонка | `not_null`, `unique`, `relationships`, `accepted_values` на `stg_orders.status` |
| **Generic (кастомный)** | `tests/generic/test_<name>.sql`, макрос Jinja с именем `test_<name>` | Любая колонка, переиспользуется по всему проекту | `tests/generic/test_non_negative.sql`, применён к `fct_orders.amount` |
| **Singular** | `tests/singular/*.sql`, самостоятельный запрос | Одно конкретное бизнес-правило | `tests/singular/assert_order_payment_amounts_match.sql` |

По сути тест dbt — это просто запрос, который должен вернуть **ноль
строк**. Если он возвращает хоть одну строку, тест падает, и именно эти
строки показывают, что не так.

### Встроенные generic-тесты

```yaml
columns:
  - name: order_id
    data_tests:
      - unique
      - not_null
  - name: customer_id
    data_tests:
      - relationships:
          to: ref('stg_customers')
          field: customer_id
  - name: status
    data_tests:
      - accepted_values:
          values: [placed, shipped, completed, return_pending, returned]
```

Четыре теста — и ни строчки SQL от вас: dbt даёт их из коробки.

### Кастомный generic-тест

```sql
-- tests/generic/test_non_negative.sql
{% test non_negative(model, column_name) %}
    select * from {{ model }}
    where {{ column_name }} < 0
{% endtest %}
```

Используется точно так же, как встроенный: `- non_negative` под любой
колонкой в любой модели, навсегда. Пишите такой, когда ловите себя на
желании повторить одну и ту же кастомную проверку на нескольких колонках.

### Singular-тест

```sql
-- tests/singular/assert_order_payment_amounts_match.sql
select order_id, amount, credit_card_amount + coupon_amount + bank_transfer_amount + gift_card_amount as recomputed_amount
from {{ ref('fct_orders') }}
where amount != credit_card_amount + coupon_amount + bank_transfer_amount + gift_card_amount
```

Пишите такой, когда проверка специфична для одной модели/бизнес-правила
и не стоит того, чтобы её обобщать.

## Практика

```bash
make shell
dbt build      # seed + run + snapshot + test, в правильном порядке зависимостей
# или просто:
dbt test
dbt test --select fct_orders
dbt test --select test_type:singular
dbt test --select test_type:generic
```

Специально что-нибудь сломайте, чтобы увидеть падение теста:

```bash
docker compose exec postgres psql -U dbt_user -d dbt_demo \
  -c "update marts.fct_orders set amount = amount + 1 where order_id = 1;"
dbt test --select fct_orders   # assert_order_payment_amounts_match теперь должен упасть
dbt run --select fct_orders    # пересборка fct_orders восстанавливает данные из источника
```

## Задание

1. Добавьте тесты `unique` + `not_null` на `dim_customers.customer_id`,
   если их ещё нет (проверьте `_core__models.yml`), затем выполните
   `dbt test --select dim_customers`.
2. Напишите новый кастомный generic-тест
   `tests/generic/test_not_empty_string.sql`, который падает, если
   текстовая колонка равна `''` (пустая строка, не null), и примените
   его к `stg_customers.email`.
3. Специально внесите баг (например, некорректный джойн) в копию
   `fct_orders.sql`, выполните `dbt test` и разберите вывод об ошибке —
   потренируйтесь идти от красного теста к первопричине.

## Чек-лист

- [ ] Могу объяснить, что делает запрос "тестом dbt" (0 строк = pass).
- [ ] Выполнил(а) `dbt test` и увидел(а) и успешный, и провальный результат.
- [ ] Написал(а) кастомный generic-тест с нуля.
- [ ] Знаю, когда браться за singular-тест вместо generic.

Далее: [07 — Макросы и Jinja](../07-macros-and-jinja/README.md)
