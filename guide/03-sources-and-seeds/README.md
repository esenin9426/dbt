# 03 — Sources и seeds

## Цель

Понять разницу между **seed** и **source** и правильно использовать оба
подхода в этом проекте.

## Теория

И seed, и source позволяют модели обратиться к "сырым" данным через
`ref()`/`source()`. Но это **не взаимозаменяемые** понятия — разница в
том, *кто загружает данные*:

| | Seed | Source |
|---|---|---|
| Кто загружает | `dbt seed` (сам dbt) | Внешний пайплайн (Fivetran, Airbyte, скрипт, человек) |
| Для чего | Небольшие, статичные, редко меняющиеся справочные данные, хранящиеся в git как CSV | Любая таблица, которая уже существует в хранилище до запуска dbt |
| Где описывается | `seeds/*.csv` + опциональный конфиг в `dbt_project.yml` | Блок `sources:` в `.yml`-файле, указывающий на существующую схему/таблицу |
| Как ссылаться | `{{ ref('raw_customers') }}` | `{{ source('raw', 'events') }}` |
| Проверка свежести | Не применимо | `dbt source freshness` |

В этом проекте:

- `dbt_project/seeds/raw_customers.csv`, `raw_orders.csv`,
  `raw_payments.csv` — это **seeds**: небольшой, вручную собранный
  демонстрационный датасет — то, что действительно можно хранить как CSV
  в git (например, справочник кодов стран, а не боевую таблицу заказов).
- `raw.events` — это **source**: см. `docker/initdb/01_raw_events.sql`,
  который создаёт схему `raw` и вставляет строки прямо в Postgres при
  первом запуске контейнера, полностью в обход dbt. Она описана в
  `dbt_project/models/staging/events/_events__sources.yml`.

Это отражает реальность: настоящие боевые сырые таблицы — это sources,
которые загружает инструмент типа Fivetran/Airbyte, а seeds оставляют
для небольших справочных данных, которыми управляет сам dbt.

### Анатомия sources.yml

```yaml
sources:
  - name: raw                # "имя источника", которое передаётся в source('raw', ...)
    schema: raw               # реальная схема в хранилище
    tables:
      - name: events           # реальное имя таблицы
        loaded_at_field: loaded_at
        freshness:
          warn_after: {count: 24, period: hour}
          error_after: {count: 48, period: hour}
```

`loaded_at_field` + `freshness` открывают команду `dbt source freshness`
— она проверяет, приходят ли сырые данные по расписанию, независимо от
того, запускались ли вообще модели.

## Практика

```bash
make shell

# Загружаем seeds (создаются таблицы в схеме `seeds`)
dbt seed

# Убеждаемся, что raw.events уже существует (создана Postgres, а не dbt)
dbt source freshness

# Список всех seeds и sources, известных dbt
dbt ls --resource-type seed
dbt ls --resource-type source
```

Откройте Adminer (http://localhost:8080) и убедитесь, что теперь видно:
- `seeds.raw_customers`, `seeds.raw_orders`, `seeds.raw_payments` (созданы `dbt seed`)
- `raw.events` (создана Postgres при старте контейнера, не dbt)

## Задание

1. Выполните `dbt source freshness` и прочитайте вывод — проверка
   проходит, потому что значения `loaded_at` достаточно свежие
   относительно `warn_after`/`error_after`. Временно поставьте
   `warn_after` в `{count: 1, period: hour}` и запустите снова, чтобы
   увидеть предупреждение. Верните значение обратно.
2. Попробуйте выполнить `dbt seed` два раза подряд. Что происходит с
   seed-таблицами? (Подсказка: seeds полностью перезагружаются, а не
   добавляются инкрементально.)
3. Одним предложением: почему `raw.events` — это source, а не seed, ведь
   и то, и другое — просто таблица со строками?

## Чек-лист

- [ ] Могу объяснить разницу seed vs source без подсказок.
- [ ] Выполнил(а) `dbt seed` и увидел(а) таблицы в Adminer.
- [ ] Успешно выполнил(а) `dbt source freshness`.
- [ ] Знаю, что `{{ ref() }}` — для моделей/seeds/snapshots, а
      `{{ source() }}` — конкретно для описанных sources.

Далее: [04 — Staging-модели](../04-staging-models/README.md)
