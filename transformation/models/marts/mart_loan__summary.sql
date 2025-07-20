with latest_fx as (
    select *
    from {{ ref('stg_staging_intermediate__fx_rates') }}
    qualify row_number() over (
        partition by currency_iso_code
        order by fx_rate_date desc
    ) = 1
),

loans_with_currency as (
    select
        l.loan_id,
        l.loan_type,
        l.loan_status,
        date_trunc('month', l.approval_rejection_date) as approval_month,
        l.loan_amount,
        l.loan_term,
        l.interest_rate,
        c.age,
        c.gender,
        a.account_id,
        t.transaction_currency as currency_iso_code,
        case
            when c.age between 18 and 25 then '18-25'
            when c.age between 26 and 35 then '26-35'
            when c.age between 36 and 45 then '36-45'
            when c.age between 46 and 60 then '46-60'
            else '60+'
        end as age_group
    from {{ ref('stg_staging_intermediate__loans') }} l
    join {{ ref('stg_staging_intermediate__customers') }} c
        on l.customer_id = c.customer_id
    join {{ ref('stg_staging_intermediate__accounts') }} a
        on c.customer_id = a.customer_id
    join {{ ref('stg_staging_intermediate__transactions') }} t
        on a.account_id = t.account_id
),

loans_with_fx as (
    select
        lwc.*,
        fx.fx_rate,
        lwc.loan_amount / fx.fx_rate as loan_amount_eur
    from loans_with_currency lwc
    left join latest_fx fx
        on fx.currency_iso_code = lwc.currency_iso_code
)

select
    age_group,
    gender,
    loan_type,
    loan_term,
    loan_status,
    approval_month,
    currency_iso_code,
    count(*) as loan_count,
    avg(interest_rate) as avg_interest_rate,
    sum(loan_amount) as total_loan_amount_original,
    sum(loan_amount_eur) as total_loan_amount_eur
from loans_with_fx
group by 1, 2, 3, 4, 5, 6, 7