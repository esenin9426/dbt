FROM python:3.11-slim

# git нужен dbt для установки пакетов из packages.yml (dbt-utils, dbt-expectations, ...)
# postgresql-client даёт `psql` внутри контейнера для ручной отладки
RUN apt-get update \
    && apt-get install -y --no-install-recommends git postgresql-client \
    && rm -rf /var/lib/apt/lists/*

ARG DBT_VERSION=1.8.*
RUN pip install --no-cache-dir \
    "dbt-core==${DBT_VERSION}" \
    "dbt-postgres==${DBT_VERSION}"

WORKDIR /usr/app/dbt

# Контейнер остаётся живым, чтобы команды выполнялись через
# `docker compose exec dbt <command>`, а не через одноразовый запуск.
CMD ["tail", "-f", "/dev/null"]
