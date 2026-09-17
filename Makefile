.PHONY: up down logs shell psql seed run test build snapshot docs docs-serve clean

up: ## Собрать и запустить Postgres + dbt + Adminer
	docker compose up -d --build

down: ## Остановить и удалить контейнеры (volume с данными Postgres сохраняется)
	docker compose down

logs: ## Смотреть логи всех сервисов
	docker compose logs -f

shell: ## Открыть shell внутри контейнера dbt
	docker compose exec dbt bash

psql: ## Открыть psql-сессию к базе данных
	docker compose exec postgres psql -U $${POSTGRES_USER:-dbt_user} -d $${POSTGRES_DB:-dbt_demo}

deps: ## Установить пакеты dbt (dbt_project/packages.yml)
	docker compose exec dbt dbt deps

seed: ## Загрузить seed-данные (CSV) в хранилище
	docker compose exec dbt dbt seed

run: ## Собрать все модели
	docker compose exec dbt dbt run

test: ## Запустить все тесты
	docker compose exec dbt dbt test

build: ## seed + run + test + snapshot в правильном порядке зависимостей
	docker compose exec dbt dbt build

snapshot: ## Сделать снапшот (см. guide/08-snapshots)
	docker compose exec dbt dbt snapshot

docs: ## Сгенерировать документацию dbt
	docker compose exec dbt dbt docs generate

docs-serve: ## Открыть документацию dbt на http://localhost:8085
	docker compose exec dbt dbt docs serve --host 0.0.0.0 --port 8085

clean: ## Удалить контейнеры И volume с данными Postgres (разрушительная операция)
	docker compose down -v
