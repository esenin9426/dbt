# 09 — Incremental-модели

## Цель

Понять, зачем нужны incremental-модели, и увидеть вживую, как модель
обрабатывает только новые строки, а не пересобирается с нуля.

## Теория

Обычная модель `table` при каждом запуске выполняет
`CREATE TABLE AS SELECT ...` (или аналог) — она **полностью** пересчитывает
результат из всех исходных данных. Для пары тысяч строк это нормально;
для источника с миллиардами строк, растущего небольшими порциями каждый
день (классика — событийные/кликстрим-данные), это болезненно медленно и
дорого.

**Incremental**-модель вместо этого:
1. На **первом** запуске (или после `--full-refresh`) строит полную
   таблицу — так же, как `table`.
2. На **каждом следующем** запуске обрабатывает только новые с прошлого
   раза строки и мержит/добавляет/удаляет-и-вставляет их в уже
   существующую таблицу.

### Incremental-модель в этом проекте

```sql
-- models/marts/events/fct_events.sql
{{ config(
    materialized='incremental',
    unique_key='event_id',
    incremental_strategy='delete+insert'
) }}

with events as (
    select * from {{ ref('stg_events') }}
    {% if is_incremental() %}
    where loaded_at > (select coalesce(max(loaded_at), '1900-01-01') from {{ this }})
    {% endif %}
)
select * from events
```

- `{{ this }}` ссылается на саму `fct_events` — при incremental-запуске
  мы обращаемся к таблице, которую строим, чтобы узнать, что там уже есть.
- `is_incremental()` возвращает `false` на первом запуске (таблицы ещё
  нет) и при `--full-refresh`, поэтому условие `where` пропускается и
  обрабатывается каждая строка.
- `incremental_strategy='delete+insert'` (Postgres поддерживает эту
  стратегию и `append`; `merge` нужен движок с поддержкой `MERGE`)
  удаляет все строки, совпадающие по `unique_key`, с теми, что
  переобрабатываются, а затем вставляет новый набор — безопасно, даже
  если один и тот же `event_id` встретится в двух партиях.

## Практика

```bash
make shell
dbt run --select stg_events fct_events    # первый запуск: полная сборка
dbt show --select fct_events --limit 5
```

Теперь имитируем **новую партию событий, поступивших** в источник — ровно
то, что сделал бы инструмент загрузки в проде, — и запустим модель
инкрементально:

```bash
docker compose exec postgres psql -U dbt_user -d dbt_demo -c "
insert into raw.events (event_id, customer_id, event_type, event_at, loaded_at) values
  (21, 6, 'page_view', now(), now()),
  (22, 6, 'checkout',  now(), now());
"

dbt run --select fct_events
```

Посмотрите на логи dbt: этот запуск затрагивает только 2 новые строки, а
не все 22. Проверьте:

```bash
docker compose exec postgres psql -U dbt_user -d dbt_demo \
  -c "select count(*) from marts.fct_events;"   # должно быть 22
```

Форсируйте полную пересборку, когда она действительно нужна (изменилась
схема, есть подозрение на порчу данных и т.д.):

```bash
dbt run --select fct_events --full-refresh
```

## Задание

1. Вставьте ещё 3 строки в `raw.events` с `loaded_at` в прошлом (раньше
   текущего максимума) и выполните `dbt run --select fct_events`.
   Подхватятся ли они? Почему да или почему нет? (Это классическая
   проблема incremental-моделей с "опоздавшими" данными — обсудите, что
   бы вы сделали с этим в реальном пайплайне.)
2. Поменяйте `incremental_strategy` на `'append'` и повторите
   последовательность insert + `dbt run` из раздела "Практика". Что
   пойдёт не так, если один и тот же `event_id` переобработается с
   `append` вместо `delete+insert`? После этого верните
   `delete+insert`.
3. Объясните одним предложением, почему `is_incremental()` возвращает
   `false` сразу после `--full-refresh`.

## Чек-лист

- [ ] Могу объяснить проблему стоимости, которую решают incremental-модели.
- [ ] Понимаю, что именно проверяет `is_incremental()`.
- [ ] Вживую увидел(а), как incremental-запуск обрабатывает только новые
      строки, через insert в psql + `dbt run`.
- [ ] Могу назвать ещё одну incremental-стратегию помимо `delete+insert`.

Далее: [10 — Пакеты](../10-packages/README.md)
