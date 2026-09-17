-- Имитирует данные, которые попали в базу из внешнего пайплайна (например,
-- Fivetran/Airbyte или сборщика кликстрима) ДО того, как вообще запустился
-- dbt. Именно это dbt называет "source" — таблица, которую dbt только
-- читает, но никогда не создаёт. Сравните с dbt_project/seeds/*.csv,
-- которые загружает сам dbt через `dbt seed`.
--
-- Временные метки считаются относительно `now()` (момента первого запуска
-- этого контейнера), чтобы `dbt source freshness` (guide/03) всегда было
-- что содержательно проверить, в какой бы день это ни запускалось.
--
-- Выполняется автоматически при первом запуске контейнера postgres на
-- чистом volume (соглашение docker-entrypoint-initdb.d).

create schema if not exists raw;

create table raw.events (
    event_id    integer primary key,
    customer_id integer not null,
    event_type  text not null,
    event_at    timestamp not null,
    loaded_at   timestamp not null
);

insert into raw.events (event_id, customer_id, event_type, event_at, loaded_at)
select
    id,
    customer_id,
    event_type,
    now() - (event_minutes_ago || ' minutes')::interval as event_at,
    now() - (event_minutes_ago - 15 || ' minutes')::interval as loaded_at
from (values
    (1,  1, 'page_view',   6690),
    (2,  1, 'add_to_cart', 6340),
    (3,  2, 'page_view',   5990),
    (4,  3, 'page_view',   5640),
    (5,  3, 'checkout',    5290),
    (6,  4, 'page_view',   4940),
    (7,  5, 'page_view',   4590),
    (8,  5, 'add_to_cart', 4240),
    (9,  6, 'page_view',   3890),
    (10, 7, 'page_view',   3540),
    (11, 7, 'checkout',    3190),
    (12, 8, 'page_view',   2840),
    (13, 9, 'page_view',   2490),
    (14, 9, 'add_to_cart', 2140),
    (15, 10, 'page_view',  1790),
    (16, 1, 'page_view',   1440),
    (17, 2, 'checkout',    1090),
    (18, 3, 'page_view',    740),
    (19, 4, 'add_to_cart',  390),
    (20, 5, 'page_view',     40)
) as e(id, customer_id, event_type, event_minutes_ago);
