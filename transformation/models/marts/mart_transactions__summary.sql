with latest_fx as (
    select *
    from {{ ref('stg_staging_intermediate__fx_rates') }}
    qualify row_number() over (
        partition by currency_iso_code
        order by fx_rate_date desc
    ) = 1
),

transactions_with_fx as (
    select
        t.transaction_id,
        t.transaction_type,
        t.transaction_currency as currency_iso_code,
        date_trunc('month', t.transaction_date) as transaction_month,
        t.transaction_amount,
        a.account_id,
        c.age,
        c.gender,
        case
            when c.age between 18 and 25 then '18-25'
            when c.age between 26 and 35 then '26-35'
            when c.age between 36 and 45 then '36-45'
            when c.age between 46 and 60 then '46-60'
            else '60+'
        end as age_group,
        fx.fx_rate,
        case
            when lower(t.transaction_currency) = 'eur' then t.transaction_amount
            else t.transaction_amount / fx.fx_rate
        end as transaction_amount_eur
    from {{ ref('stg_staging_intermediate__transactions') }} t
    join {{ ref('stg_staging_intermediate__accounts') }} a
        on t.account_id = a.account_id
    join {{ ref('stg_staging_intermediate__customers') }} c
        on a.customer_id = c.customer_id
    left join latest_fx fx
        on lower(t.transaction_currency) = lower(fx.currency_iso_code)
)

select
    age_group,
    gender,
    transaction_type,
    currency_iso_code,
    transaction_month,
    count(*) as transaction_count,
    round(sum(transaction_amount_eur), 2) as total_transaction_amount_eur
from transactions_with_fx
group by 1, 2, 3, 4, 5
