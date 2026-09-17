# 07 — Макросы и Jinja

## Цель

Писать переиспользуемую SQL-логику через макросы Jinja и понимать, как
dbt позволяет переопределять собственные внутренние макросы.

## Теория

dbt компилирует каждый `.sql`-файл через шаблонизатор **Jinja**, прежде
чем отправить его в хранилище. Макросы — это функции Jinja, которые
возвращают текст SQL.

### Простой макрос

```sql
-- macros/cents_to_dollars.sql
{% macro cents_to_dollars(column_name) %}
    ({{ column_name }} / 100.0)
{% endmacro %}
```

Используется в `stg_payments.sql` как `{{ cents_to_dollars('amount') }}`.
На этапе компиляции это превращается в обычный SQL — выполните
`dbt compile` и посмотрите на `target/compiled/.../stg_payments.sql`,
там будет `(amount / 100.0)`.

### Управляющие конструкции

Jinja даёт `{% if %}`, `{% for %}` и переменные прямо внутри SQL.
Incremental-модель в этом проекте использует именно это:

```sql
{% if is_incremental() %}
where loaded_at > (select coalesce(max(loaded_at), '1900-01-01') from {{ this }})
{% endif %}
```

`is_incremental()` — встроенный макрос, который возвращает `true` только
когда: модель настроена как `materialized='incremental'`, целевая
таблица уже существует, и вы не передали `--full-refresh`. Этап 09
разбирает это подробно.

### Переопределение внутренних макросов dbt

Сам dbt во многом реализован через макросы — и некоторые из них можно
переопределять как точки расширения. В этом проекте переопределён
`generate_schema_name` в `macros/generate_schema_name.sql`:

```sql
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
```

По умолчанию dbt склеивает `<target_schema>_<custom_schema>` (например,
`dbt_dev_marts`). Мы переопределяем это, чтобы использовать имя схемы как
есть (`marts`, `staging`, `seeds`) — так гораздо удобнее ориентироваться в
Adminer для проекта с одной базой данных. Это тот же паттерн, который
dbt Labs сама документирует как "generate_schema_name_for_env";
практически любой боевой проект так или иначе переопределяет этот
макрос.

### `{{ this }}`, `{{ target }}`, `{{ ref }}` как объекты Jinja

Внутри любого скомпилированного SQL-файла доступны:
- `{{ this }}` — relation текущей модели (используется выше для фильтра
  в incremental-модели).
- `{{ target }}` — информация о текущем подключении (`target.schema`,
  `target.name` и т.д.).
- `{{ ref(...) }}` / `{{ source(...) }}` — как уже видели ранее.

## Практика

```bash
make shell

# Смотрим, во что реально компилируется макрос, ничего не запуская
dbt compile --select stg_payments
cat target/compiled/dbt_demo/models/staging/jaffle_shop/stg_payments.sql
```

Попробуйте отключить переопределение схемы, чтобы увидеть поведение по
умолчанию:

```bash
mv macros/generate_schema_name.sql macros/generate_schema_name.sql.bak
dbt run --select stg_customers --full-refresh
# проверьте в Adminer: схема теперь выглядит как dbt_dev_staging
mv macros/generate_schema_name.sql.bak macros/generate_schema_name.sql
dbt run --select stg_customers --full-refresh   # снова схема "staging"
```

## Задание

1. Напишите макрос `macros/dollars_to_cents.sql` — обратный
   `cents_to_dollars`, — даже если в проекте он пока не нужен.
   Убедитесь, что он компилируется через пробный `dbt compile`.
2. Прочитайте `macros/generate_schema_name.sql` построчно и объясните,
   что происходит, когда у модели **нет** конфига `+schema` вообще
   (`custom_schema_name is none`).
3. Добавьте цикл `{% for %}` в черновой макрос, который генерирует
   `sum(case when x = 'a' then 1 else 0 end) as a_count` для списка
   переданных значений — это тот же паттерн, что лежит в основе
   "pivot"-макросов вроде `dbt_utils.pivot`.

## Чек-лист

- [ ] Могу написать базовый макрос, принимающий аргумент и возвращающий SQL.
- [ ] Понимаю `is_incremental()` и где он используется в этом проекте.
- [ ] Могу объяснить, что меняет `generate_schema_name.sql` и зачем.
- [ ] Использовал(а) `dbt compile`, чтобы посмотреть, во что реально
      скомпилировался Jinja.

Далее: [08 — Снапшоты (SCD Type 2)](../08-snapshots/README.md)
