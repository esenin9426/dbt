{{
    config(
        materialized='incremental',
        unique_key='event_id',
        incremental_strategy='delete+insert'
    )
}}

with events as (

    select * from {{ ref('stg_events') }}

    {% if is_incremental() %}
    -- Начиная со второго запуска обрабатываем только строки, загруженные
    -- позже самого свежего `loaded_at`, уже сохранённого в этой таблице.
    -- См. guide/09-incremental-models.
    where loaded_at > (select coalesce(max(loaded_at), '1900-01-01') from {{ this }})
    {% endif %}

)

select
    event_id,
    customer_id,
    event_type,
    event_at,
    loaded_at
from events
