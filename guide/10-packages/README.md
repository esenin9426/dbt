# 10 — Пакеты

## Цель

Установить пакет от сообщества dbt и использовать из него и макрос, и
generic-тест.

## Теория

Пакеты dbt — это git-репозитории с макросами/моделями/тестами, которые
можно установить в свой проект — аналог библиотеки для dbt. Самый
популярный из них — [`dbt-utils`](https://github.com/dbt-labs/dbt-utils),
который поддерживает сама dbt Labs: множество кросс-платформенных
макросов и generic-тестов, которые иначе пришлось бы писать самому.

### Подключение пакета

```yaml
# dbt_project/packages.yml
packages:
  - package: dbt-labs/dbt_utils
    version: [">=1.1.0", "<2.0.0"]
```

Пакеты устанавливаются командой `dbt deps` в `dbt_packages/`
(добавлено в .gitignore — установленные пакеты никогда не коммитятся, в
git попадает только `packages.yml`). Любой, кто клонирует этот
репозиторий, один раз выполняет `dbt deps` и получает точно те же версии
пакетов.

### Полезные возможности dbt_utils

- `dbt_utils.generate_surrogate_key(['col_a', 'col_b'])` — хэширует
  несколько колонок в один детерминированный ключ. Стандартный способ
  построить первичный ключ, если естественного нет.
- `dbt_utils.star(from=ref('some_model'), except=['col_to_exclude'])` —
  разворачивается во все колонки, кроме перечисленных.
- `dbt_utils.date_spine(...)` — генерирует календарь/дату как измерение.
- Generic-тесты: `dbt_utils.unique_combination_of_columns`,
  `dbt_utils.expression_is_true`, `dbt_utils.not_constant`,
  `dbt_utils.accepted_range`.

## Практика

```bash
make shell
dbt deps                      # ставит dbt_utils согласно packages.yml
ls dbt_packages/              # убеждаемся, что пакет на месте
```

Используйте макрос dbt_utils прямо в модели. Добавьте этот тест в
`_core__models.yml` под `fct_orders` (проверка составной уникальности —
для этого у dbt нет встроенного generic-теста):

```yaml
data_tests:
  - dbt_utils.unique_combination_of_columns:
      combination_of_columns:
        - order_id
        - customer_id
```

```bash
dbt test --select fct_orders
```

Попробуйте `dbt_utils.expression_is_true` как лёгкую альтернативу
singular-тесту — добавьте его на уровне модели (не колонки) под
`fct_orders`:

```yaml
models:
  - name: fct_orders
    data_tests:
      - dbt_utils.expression_is_true:
          expression: "amount = credit_card_amount + coupon_amount + bank_transfer_amount + gift_card_amount"
```

## Задание

1. Выполните `dbt deps` и убедитесь, что `dbt_packages/dbt_utils/`
   появился.
2. Добавьте оба теста выше в `_core__models.yml`, выполните
   `dbt test --select fct_orders` и убедитесь, что они проходят.
3. Перепишите логику `macros/generate_schema_name.sql`, используя
   `dbt_utils.generate_surrogate_key` в черновой модели, просто чтобы
   увидеть, во что это компилируется — сохранять изменение не нужно.
4. (Опционально, для продвинутых) Посмотрите на
   `dbt-labs/dbt_expectations` — более крупный пакет тестов, вдохновлённый
   Python-библиотекой Great Expectations — и прочитайте названия 3
   интересных вам тестов. Устанавливать необязательно — цель в том, чтобы
   узнать: богатая экосистема тестов существует.

## Чек-лист

- [ ] Могу объяснить, что делают `packages.yml` + `dbt deps` и почему
      `dbt_packages/` в `.gitignore`.
- [ ] Использовал(а) хотя бы один generic-тест из dbt_utils в этом проекте.
- [ ] Знаю, что dbt_utils поддерживает dbt Labs и по сути является
      "стандартной библиотекой" для проектов dbt.

Далее: [11 — Документация](../11-documentation/README.md)
