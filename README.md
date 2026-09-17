# dbt Demo Project — от нуля до профи

Полностью автономный демонстрационный проект на dbt: рабочая инфраструктура
аналитики (Postgres + dbt Core) в Docker плюс пошаговое руководство из 15
этапов, которое разбирает все ключевые концепции dbt на этом же проекте.

Проект сделан для двух целей:
- **Портфолио** — рабочий, протестированный, документированный проект с
  CI, который можно показать работодателю вместо строчки "знаю dbt" в
  резюме.
- **Учебный материал** — пошаговое руководство, которое можно передать
  ученикам: теория, команды, которые реально можно выполнить, задания и
  чек-листы на каждом этапе.

## Быстрый старт

```bash
git clone <этот репозиторий>
cd dbt
cp .env.example .env
make up              # docker compose up -d --build: Postgres + dbt + Adminer
make shell            # открыть shell внутри контейнера dbt
dbt debug             # проверить подключение к базе
dbt build             # seed + run + test + snapshot в правильном порядке
dbt docs generate && dbt docs serve --host 0.0.0.0 --port 8085
```

Затем откройте:
- **http://localhost:8085** — документация dbt (граф зависимостей, описания моделей и колонок)
- **http://localhost:8080** — Adminer (просмотр базы Postgres напрямую)

Все команды — в `Makefile` (`make up/down/shell/psql/seed/run/test/build/
docs/docs-serve/clean`).

## План проекта

| Слой | Что это | Где |
|---|---|---|
| Инфраструктура | Postgres (хранилище), dbt (CLI в контейнере), Adminer (просмотр БД) | `docker-compose.yml`, `docker/` |
| Сырые данные | Небольшой датасет в стиле jaffle-shop (клиенты, заказы, платежи) как **seeds**, плюс таблица-**источник** кликстрима (`raw.events`), загруженная вне dbt | `dbt_project/seeds/`, `docker/initdb/` |
| Staging | Очищенные представления 1:1 над сырыми данными | `dbt_project/models/staging/` |
| Marts | Бизнес-таблицы (факты/измерения), включая одну incremental-модель | `dbt_project/models/marts/` |
| История | SCD Type 2 снапшот таблицы клиентов | `dbt_project/snapshots/` |
| Качество данных | Встроенные, кастомные generic- и singular-тесты | `dbt_project/tests/`, `*.yml` |
| Переиспользование | Собственные макросы + зависимость от пакета `dbt-utils` | `dbt_project/macros/`, `packages.yml` |
| Документация | Описания, `{% docs %}`-блоки, exposure, автоматический граф зависимостей | по всему `*.yml`/`*.md`, `dbt docs` |
| CI/CD | `dbt build` запускается автоматически на каждый pull request | `.github/workflows/dbt_ci.yml` |
| Руководство | 15 этапов, последовательно разбирающих всё вышеперечисленное | `guide/` |

Полная структура репозитория:

```
dbt/
├── docker-compose.yml         # Postgres + dbt + Adminer
├── docker/
│   ├── dbt.Dockerfile          # образ с dbt-core + dbt-postgres
│   └── initdb/                 # наполняет схему `raw` (таблицу-"источник")
├── Makefile                    # `make up/down/shell/build/docs/...`
├── .env.example
├── .github/workflows/dbt_ci.yml
├── dbt_project/                 # сам проект dbt
│   ├── dbt_project.yml
│   ├── packages.yml
│   ├── profiles/profiles.yml     # таргеты dev / prod / ci
│   ├── seeds/                     # raw_customers, raw_orders, raw_payments
│   ├── models/
│   │   ├── staging/                # stg_customers, stg_orders, stg_payments, stg_events
│   │   └── marts/
│   │       ├── core/                # dim_customers, fct_orders
│   │       └── events/              # fct_events (incremental)
│   ├── snapshots/customers_snapshot.sql
│   ├── macros/                     # cents_to_dollars, generate_schema_name
│   ├── tests/                      # generic/test_non_negative.sql, singular/*.sql
│   └── analyses/
└── guide/                        # пошаговое руководство — начните с guide/README.md
```

## План изучения

Руководство лежит в [`guide/`](./guide/README.md): 15 этапов, каждый —
отдельный `README.md` со структурой **Цель → Теория → Практика → Задание
→ Чек-лист**:

00. Введение в dbt и analytics engineering
01. Настройка окружения (Docker, Postgres, dbt, Adminer)
02. Структура проекта и материализации (view/table/incremental/ephemeral)
03. Sources и seeds (и когда что использовать)
04. Staging-модели
05. Marts и dimensional-моделирование (факты и измерения)
06. Тестирование (встроенные generic, кастомные generic, singular)
07. Макросы и Jinja (включая переопределение внутренних макросов dbt)
08. Снапшоты (SCD Type 2)
09. Incremental-модели
10. Пакеты (`dbt-utils`)
11. Документация (`dbt docs`, `{% docs %}`-блоки, граф зависимостей)
12. CI/CD (GitHub Actions запускает `dbt build` на каждый PR)
13. Продвинутые темы (exposures, hooks, Slim CI, semantic layer и dbt Mesh — обзор)
14. Итоговый проект (расширить всё самостоятельно и представить как портфолио)

**Начните здесь → [`guide/README.md`](./guide/README.md)**

## Стек технологий

- [dbt Core](https://github.com/dbt-labs/dbt-core) 1.8 + `dbt-postgres`
- PostgreSQL 16
- Docker / Docker Compose
- Adminer (лёгкий просмотрщик БД)
- GitHub Actions (CI)
- пакет [`dbt-utils`](https://github.com/dbt-labs/dbt-utils)

Локально не нужно ставить ни Python, ни dbt — всё, включая CLI dbt,
работает внутри контейнеров.
