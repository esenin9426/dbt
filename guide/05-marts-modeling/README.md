# 05 — Marts и Dimensional-моделирование

## Цель

Строить бизнес-таблицы поверх staging-моделей и разбираться в
терминологии facts/dimensions достаточно, чтобы уверенно оперировать ей
на собеседовании.

## Теория

### Facts vs dimensions

- **Fact-таблица (таблица фактов)**: одна строка на бизнес-событие/
  транзакцию, в основном числовые метрики + внешние ключи. Растёт со
  временем. Пример: `models/marts/core/fct_orders.sql` — одна строка на
  заказ, с суммами.
- **Dimension-таблица (таблица измерений)**: одна строка на бизнес-
  сущность, в основном описательные атрибуты, часто с агрегатами,
  свёрнутыми из фактов. Пример: `models/marts/core/dim_customers.sql` —
  одна строка на клиента, с `lifetime_value`, вычисленным из его заказов.

Это облегчённая версия dimensional-моделирования в стиле Кимбалла — не
нужна полноценная звёздная схема с суррогатными ключами и согласованными
измерениями, чтобы получить пользу: одно только соглашение об именовании
(`fct_`/`dim_`) делает намерение проекта понятным для любого, кто его
открывает.

### Разбор fct_orders.sql

```sql
with orders as ( select * from {{ ref('stg_orders') }} ),
     payments as ( select * from {{ ref('stg_payments') }} ),
     order_payments as (
         select order_id,
                sum(case when payment_method = 'credit_card' then amount else 0 end) as credit_card_amount,
                ...
                sum(amount) as total_amount
         from payments
         group by order_id
     ),
     final as (
         select orders.*, order_payments.*
         from orders
         left join order_payments on orders.order_id = order_payments.order_id
     )
select * from final
```

Обратите внимание на паттерн: **import-CTE** (`orders`, `payments` —
просто `ref()` с коротким алиасом для каждого), **логическая CTE**
(`order_payments` — собственно трансформация) и **финальная CTE**, в
которой внизу всегда ровно `select * from final`. Такая структура (из
style guide самого dbt Labs) делает любую модель предсказуемой для
чтения, независимо от того, кто её написал.

### Разбор dim_customers.sql

`dim_customers` зависит от `fct_orders` (mart зависит от другого mart),
а не напрямую от `stg_orders` — потому что нужная агрегация (сумма по
заказу) уже решена один раз в `fct_orders`. Не пересчитывайте логику,
которая уже есть ниже по графу зависимостей.

## Практика

```bash
make shell
dbt run --select marts.core
dbt show --select dim_customers --limit 10
dbt show --select fct_orders --limit 10
```

Посмотрите на построенный dbt граф зависимостей:

```bash
dbt ls --select +dim_customers --output path
```

## Задание

1. Добавьте новый mart `models/marts/core/dim_orders_by_status.sql`:
   одна строка на `status`, с `count(*) as number_of_orders` и
   `sum(amount) as total_amount`, построенный на `fct_orders`. Добавьте
   соответствующую запись в `_core__models.yml` хотя бы с одним тестом.
2. Выполните `dbt run --select dim_orders_by_status` и проверьте
   результат в Adminer.
3. Объясните, почему `dim_customers` джойнится с `fct_orders`, а не
   напрямую со `stg_orders` + `stg_payments`.

## Чек-лист

- [ ] Могу по памяти дать определение fact-таблицы и dimension-таблицы.
- [ ] Могу показать структуру import/логическая/финальная CTE в любой
      модели этого проекта.
- [ ] Добавил(а) новый mart и подключил(а) для него схему/тесты.
- [ ] Понимаю, что marts могут зависеть от других marts, а не только от staging.

Далее: [06 — Тестирование](../06-testing/README.md)
