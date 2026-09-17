{% docs stg_customers %}
Staging-модель поверх seed-таблицы `raw_customers`. Одна строка на клиента,
колонки переименованы в понятные человеку названия. Именно на эту модель
должна ссылаться любая нижестоящая таблица, связанная с клиентами — вместо
прямого обращения к сырому seed.
{% enddocs %}

{% docs stg_orders %}
Staging-модель поверх seed-таблицы `raw_orders`. Одна строка на заказ.
`status` отражает жизненный цикл заказа (`placed` → `shipped` →
`completed`, либо `return_pending` → `returned`).
{% enddocs %}
