with accounts as (
    select * from "casestudy"."intermediate"."stg_staging_intermediate__accounts"
),
customers as (
    select * from "casestudy"."intermediate"."stg_staging_intermediate__customers"
),
transactions as (
    select * from "casestudy"."intermediate"."stg_staging_intermediate__transactions"
),
fx_rates as (
    select * from "casestudy"."intermediate"."stg_staging_intermediate__fx_rates"
),
loans as (
    select * from "casestudy"."intermediate"."stg_staging_intermediate__loans"
),

fx_latest as (
    select * from "casestudy"."intermediate"."stg_staging_intermediate__fx_rates"
),

transactions_with_fx as (
    select
        t.account_id,
        t.transaction_amount,
        t.transaction_currency,
        t.transaction_date,
        fx.fx_rate,
        fx.fx_rate_date,
        case 
            when fx.fx_rate is not null and fx.fx_rate > 0 
            then t.transaction_amount / fx.fx_rate 
            else null 
        end as transaction_amount_eur
    from transactions t
    left join fx_rates fx
        on trim(upper(t.transaction_currency)) = trim(upper(fx.currency_iso_code))
),

transaction_summary as (
    select
        account_id,
        transaction_currency,
        sum(transaction_amount) as total_transaction_amount,
        sum(transaction_amount_eur) as total_transaction_amount_eur
    from transactions_with_fx
    group by account_id, transaction_currency
),
final as (
    select
        c.customer_id,
        c.firstname,
        c.lastname,
        c.age,
        a.account_id,
        a.account_type,
        a.account_opening_date,
        ts.transaction_currency,
        ts.total_transaction_amount,
        ts.total_transaction_amount_eur,
        l.loan_status,
        l.loan_amount,
        l.interest_rate
    from customers c
    left join accounts a on c.customer_id = a.customer_id
    left join transaction_summary ts on a.account_id = ts.account_id
    left join loans l on c.customer_id = l.customer_id
    left join fx_rates fx on fx.currency_iso_code = 'EUR'
)

select * from final