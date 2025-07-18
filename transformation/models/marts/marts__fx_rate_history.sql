with fx_data as (
    select *
    from {{ ref('stg_staging_intermediate__fx_rates') }}
),
ranked as (
    select *,
           lag(fx_rate) over (partition by currency_iso_code order by fx_rate_date) as prev_fx_rate,
           avg(fx_rate) over (partition by currency_iso_code order by fx_rate_date rows between 6 preceding and current row) as moving_average_fx_rate
    from fx_data
)
select
    currency_iso_code,
    fx_rate_date,
    fx_rate,
    fx_rate - prev_fx_rate as fx_rate_change,
    moving_average_fx_rate
from ranked
