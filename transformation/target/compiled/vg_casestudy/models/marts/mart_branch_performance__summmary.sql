with latest_fx as (
    select *
    from "casestudy"."intermediate"."stg_staging_intermediate__fx_rates"
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
        date_trunc('month', l.approval_rejection_date) as month,
        l.loan_amount,
        l.loan_term,
        l.interest_rate,
        c.age,
        c.gender,
        c.branch_id,
        a.account_id,
        t.transaction_currency as currency_iso_code,
        case
            when c.age between 18 and 25 then '18-25'
            when c.age between 26 and 35 then '26-35'
            when c.age between 36 and 45 then '36-45'
            when c.age between 46 and 60 then '46-60'
            else '60+'
        end as age_group
    from "casestudy"."intermediate"."stg_staging_intermediate__loans" l
    join "casestudy"."intermediate"."stg_staging_intermediate__customers" c
        on l.customer_id = c.customer_id
    join "casestudy"."intermediate"."stg_staging_intermediate__accounts" a
        on c.customer_id = a.customer_id
    join "casestudy"."intermediate"."stg_staging_intermediate__transactions" t
        on a.account_id = t.account_id
    where l.loan_status = 'approved'
),

loans_with_fx as (
    select
        lwc.*,
        fx.fx_rate,
        coalesce(lwc.loan_amount / fx.fx_rate, 0) as loan_amount_eur
    from loans_with_currency lwc
    left join latest_fx fx
        on lower(fx.currency_iso_code) = lower(lwc.currency_iso_code)

),

transactions_with_fx as (
    select
        t.transaction_id,
        t.transaction_type,
        date_trunc('month', t.transaction_date) as month,
        t.transaction_amount,
        t.transaction_currency as currency_iso_code,
        c.gender,
        c.branch_id,
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
    from "casestudy"."intermediate"."stg_staging_intermediate__transactions" t
    join "casestudy"."intermediate"."stg_staging_intermediate__accounts" a
        on t.account_id = a.account_id
    join "casestudy"."intermediate"."stg_staging_intermediate__customers" c
        on a.customer_id = c.customer_id
    left join latest_fx fx
        on lower(t.transaction_currency) = lower(fx.currency_iso_code)
),

loan_summary as (
    select
        branch_id,
        month,
        gender,
        age_group,
        count(*) as total_loan_count,
        round(sum(loan_amount_eur), 2) as total_loan_amount_eur
    from loans_with_fx
    group by 1, 2, 3, 4
),

transaction_summary as (
    select
        branch_id,
        month,
        gender,
        age_group,
        count(*) as total_transaction_count,
        round(sum(transaction_amount_eur), 2) as total_transaction_amount_eur
    from transactions_with_fx
    group by 1, 2, 3, 4
)

select
    coalesce(l.branch_id, t.branch_id) as branch_id,
    coalesce(l.month, t.month) as month,
    coalesce(l.gender, t.gender) as gender,
    coalesce(l.age_group, t.age_group) as age_group,
    coalesce(total_loan_count, 0) as total_loan_count,
    coalesce(total_loan_amount_eur, 0) as total_loan_amount_eur,
    coalesce(total_transaction_count, 0) as total_transaction_count,
    coalesce(total_transaction_amount_eur, 0) as total_transaction_amount_eur
from loan_summary l
full outer join transaction_summary t
    on l.branch_id = t.branch_id
    and l.month = t.month
    and l.gender = t.gender
    and l.age_group = t.age_group