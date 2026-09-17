# 12 — CI/CD

## Цель

Разобраться и опробовать workflow GitHub Actions, который собирает и
тестирует этот проект dbt на каждый pull request.

## Теория

Относиться к проекту dbt как к настоящему программному продукту означает
и то, что ему нужен CI-пайплайн: каждый pull request должен доказать, что
`dbt build` по-прежнему проходит чисто (seeds загружаются, модели
компилируются и строятся, тесты проходят), прежде чем мержиться.

### Workflow: `.github/workflows/dbt_ci.yml`

```yaml
on:
  pull_request:
    paths:
      - "dbt_project/**"
      - ".github/workflows/dbt_ci.yml"

jobs:
  dbt-build:
    services:
      postgres:            # одноразовый Postgres, только для этого запуска CI
        image: postgres:16-alpine
        ...
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
      - run: pip install dbt-core dbt-postgres
      - run: dbt deps
      - run: dbt debug --target ci
      - run: dbt build --target ci
```

Две вещи делают это переносимым между вашим ноутбуком и GitHub Actions:

1. **Таргет `ci`** в `dbt_project/profiles/profiles.yml`, у которого
   `host` по умолчанию `postgres` (имя сервиса docker-compose), но
   резолвится в `localhost` в CI через переменную окружения `DBT_HOST` —
   потому что в GitHub Actions "сервисы" доступны по localhost, а не по
   имени сервиса, из шагов самого job'а.
2. Использование **`dbt build`** вместо отдельных вызовов
   `seed`/`run`/`test`/`snapshot` — `dbt build` выполняет всё в
   правильном порядке DAG одной командой, что для CI как раз и нужно.

## Практика

GitHub-remote для этого не обязателен — можно выполнить почти те же
шаги, что и в workflow, вручную, на том же docker-compose postgres:

```bash
# имитируем то, что делает CI, используя ТОТ ЖЕ docker-compose postgres
make shell
DBT_HOST=postgres dbt debug --target ci
DBT_HOST=postgres dbt build --target ci
```

Если вы всё же запушили этот репозиторий на GitHub:

```bash
git push -u origin <ваша-ветка>
gh pr create --fill   # или откройте PR в интерфейсе GitHub
```

Понаблюдайте за проверкой "dbt CI" на PR — она должна стать зелёной,
если `dbt build` проходит и локально.

## Задание

1. Специально сломайте тест (например, уберите `'returned'` из списка
   `accepted_values` для `stg_orders.status`), закоммитьте это в ветку,
   откройте PR и посмотрите, как CI станет красным. Затем исправьте и
   посмотрите, как он позеленеет.
2. Прочитайте таргет `ci` в `dbt_project/profiles/profiles.yml` и
   объясните, что делает `env_var('DBT_HOST', 'postgres')`, когда
   `DBT_HOST` вообще не задана (например, при обычном `dbt build` внутри
   контейнера dbt).
3. (Опционально, для продвинутых) Добавьте в workflow шаг, который
   выполняет `dbt docs generate` и загружает `target/` как артефакт
   сборки (`actions/upload-artifact@v4`), чтобы ревьюеры могли скачать и
   посмотреть документацию для этого PR.

## Чек-лист

- [ ] Могу объяснить, зачем CI нужен собственный таргет `ci`, а не
      переиспользование `dev`.
- [ ] Запустил(а) workflow (или повторил(а) его шаги локально) и увидел(а)
      успешное прохождение.
- [ ] Увидел(а), как сломанный тест роняет CI, и исправил(а) это.
- [ ] Понимаю, почему в контексте CI предпочтительнее `dbt build`, а не
      отдельные команды.

Далее: [13 — Продвинутые темы](../13-advanced-topics/README.md)
