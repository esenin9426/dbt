# Пошаговое руководство по dbt

Путь от «что такое dbt» до запуска протестированного, документированного,
incremental-проекта — на том самом `dbt_project/`, что лежит в этом
репозитории, и на инфраструктуре, которую поднимает `docker-compose.yml`.

Каждый этап — папка со своим `README.md`: **Цель → Теория → Практика →
Задание → Чек-лист**. В первый раз проходите по порядку; дальше — это уже
справочник.

| # | Этап | После этого вы сможете... |
|---|------|----------------------------|
| [00](../guide/00-introduction/README.md) | Введение в dbt и analytics engineering | Объяснить, что такое dbt, разницу ELT и ETL, и место dbt в стеке данных |
| [01](../guide/01-environment-setup/README.md) | Настройка окружения | Поднять Postgres + dbt через Docker и выполнить первый `dbt debug` |
| [02](../guide/02-project-structure/README.md) | Структура проекта и материализации | Ориентироваться в проекте dbt и осознанно выбирать view/table/ephemeral |
| [03](../guide/03-sources-and-seeds/README.md) | Sources и seeds | Загружать CSV командой `dbt seed` и описывать/тестировать сырые таблицы через `sources:` |
| [04](../guide/04-staging-models/README.md) | Staging-модели | Писать чистые staging-модели один-к-одному с помощью `ref()` |
| [05](../guide/05-marts-modeling/README.md) | Marts и dimensional-моделирование | Строить fact/dimension-marts (в духе звёздной схемы) поверх staging |
| [06](../guide/06-testing/README.md) | Тестирование | Добавлять generic-, кастомные generic- и singular-тесты, запускать `dbt test` |
| [07](../guide/07-macros-and-jinja/README.md) | Макросы и Jinja | Писать переиспользуемые макросы, использовать управляющие конструкции, переопределять макросы самого dbt |
| [08](../guide/08-snapshots/README.md) | Снапшоты (SCD Type 2) | Отслеживать изменения изменяемой исходной таблицы во времени |
| [09](../guide/09-incremental-models/README.md) | Incremental-модели | Строить модель, которая обрабатывает только новые/изменённые строки |
| [10](../guide/10-packages/README.md) | Пакеты | Устанавливать и использовать `dbt-utils` через `packages.yml` |
| [11](../guide/11-documentation/README.md) | Документация | Писать описания/`docs`-блоки и поднимать сайт документации dbt |
| [12](../guide/12-ci-cd/README.md) | CI/CD | Запускать `dbt build` автоматически на каждый pull request через GitHub Actions |
| [13](../guide/13-advanced-topics/README.md) | Продвинутые темы | Exposures, hooks, `state:modified` (slim CI), обзор semantic layer, dbt Mesh |
| [14](../guide/14-final-project/README.md) | Итоговый проект | Самостоятельно расширить проект и представить его как элемент портфолио |

## Что нужно знать заранее

- Базовый SQL (`SELECT`, `JOIN`, `GROUP BY`).
- Установленный и запущенный Docker Desktop (или совместимый движок).
- Уверенное владение терминалом.

Локальный Python или dbt не нужны — всё работает в контейнерах,
описанных в `docker-compose.yml` в корне репозитория.

## Как всё это связано

```
docker-compose.yml        → поднимает Postgres (хранилище), dbt (CLI), Adminer (просмотр БД)
dbt_project/               → сам проект dbt, который вы расширяете этап за этапом
  seeds/                   → raw_customers, raw_orders, raw_payments, (события — через source)
  models/staging/          → очищенные представления 1:1 над seeds/sources
  models/marts/            → бизнес-таблицы (факты/измерения)
  snapshots/               → история SCD2 по raw_customers
  macros/                  → переиспользуемый Jinja + кастомный generic-тест
  tests/                   → кастомный generic-тест + singular-тест
guide/                    → это руководство, отдельная папка на каждый этап
```

Начните с [этапа 00](../guide/00-introduction/README.md).
