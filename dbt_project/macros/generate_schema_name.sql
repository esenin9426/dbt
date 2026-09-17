{#
  Переопределяет стандартный макрос dbt для формирования имени схемы.

  По умолчанию `+schema: marts` в dbt_project.yml собирает модели в схему
  вида `<target_schema>_marts` (например, `dbt_dev_marts`). Это удобно в
  общем хранилище, но избыточно для этого проекта с одной базой данных —
  поэтому мы используем указанную схему как есть и откатываемся на схему
  target только если модель вообще не задала свою. Это тот же паттерн,
  что dbt Labs описывает как "generate_schema_name_for_env" — см.
  guide/07-macros-and-jinja.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- else -%}

        {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
