
  
    
    

    create  table
      "casestudy"."mart"."mart_branch_performance__summary__dbt_tmp"
  
    as (
      with latest_fx as (
    select *
    from "casestudy"."intermediate"."stg_staging_intermediate__fx_rates"
    qualify row_number() over (
        partition by currency_iso_code
        order by fx_rate_date desc
    ) = 1
),

-- LOAN DATA TO EUR
loans_with_fx as (
    select
        l.customer_id,
        c.branch_id,
        date_trunc('month', l.approval_rejection_date) as month,
        l.loan_status,
        l.loan_amount,
        l.currency_iso_code,
        fx.fx_rate,
        l.loan_amount / fx.fx_rate as loan_amount_eur
    from "casestudy"."intermediate"."stg_staging_intermediate__loans" l
    join "casestudy"."intermediate"."stg_staging_intermediate__customers" c
        on l.customer_id = c.customer_id
    left join latest_fx fx
        on fx.currency_iso_code = l.currency_iso_code
    where l.loan_status = 'approved'
),

-- TRANSACTION DATA TO EUR
transactions_with_fx as (
    select
        c.branch_id,
        date_trunc('month', t.transaction_date) as month,
        t.transaction_amount,
        t.transaction_currency,
        fx.fx_rate,
        t.transaction_amount * fx.fx_rate as transaction_amount_eur
    from "casestudy"."intermediate"."stg_staging_intermediate__transactions" t
    join "casestudy"."intermediate"."stg_staging_intermediate__accounts" a
        on t.account_id = a.account_id
    join "casestudy"."intermediate"."stg_staging_intermediate__customers" c
        on a.customer_id = c.customer_id
    left join latest_fx fx
        on t.transaction_currency = fx.currency_iso_code
),

-- LOAN SUMMARY
loan_summary as (
    select
        branch_id,
        month,
        count(*) as total_loan_count,
        sum(loan_amount_eur) as total_loan_amount_eur
    from loans_with_fx
    group by branch_id, month
),

-- TRANSACTION SUMMARY
transaction_summary as (
    select
        branch_id,
        month,
        count(*) as total_transaction_count,
        sum(transaction_amount_eur) as total_transaction_amount_eur
    from transactions_with_fx
    group by branch_id, month
)

-- MERGE 
select
    coalesce(l.branch_id, t.branch_id) as branch_id,
    coalesce(l.month, t.month) as month,
    coalesce(total_loan_count, 0) as total_loan_count,
    coalesce(total_loan_amount_eur, 0) as total_loan_amount_eur,
    coalesce(total_transaction_count, 0) as total_transaction_count,
    coalesce(total_transaction_amount_eur, 0) as total_transaction_amount_eur
from loan_summary l
full outer join transaction_summary t
    on l.branch_id = t.branch_id and l.month = t.month
    );
  
  