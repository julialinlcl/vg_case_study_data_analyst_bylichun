
  
    
    

    create  table
      "casestudy"."marts"."marts__customer_financial_profile__dbt_tmp"
  
    as (
      with accounts as (
    select customer_id, count(*) as total_accounts
    from "casestudy"."intermediate"."stg_staging_intermediate__accounts"
    group by customer_id
),
transactions as (
    select a.customer_id,
           count(*) as total_transactions,
           sum(t.transaction_amount) as total_transaction_amount
    from "casestudy"."intermediate"."stg_staging_intermediate__transactions" t
    join "casestudy"."intermediate"."stg_staging_intermediate__accounts" a
      on t.account_id = a.account_id
    group by a.customer_id
),
loans as (
    select customer_id,
           count(*) as total_loans,
           sum(loan_amount) as total_loan_amount,
           avg(interest_rate) as average_interest_rate
    from "casestudy"."intermediate"."stg_staging_intermediate__loans"
    group by customer_id
)
select
    c.customer_id,
    coalesce(a.total_accounts, 0) as total_accounts,
    coalesce(t.total_transactions, 0) as total_transactions,
    coalesce(t.total_transaction_amount, 0) as total_transaction_amount,
    coalesce(l.total_loans, 0) as total_loans,
    coalesce(l.total_loan_amount, 0) as total_loan_amount,
    coalesce(l.average_interest_rate, 0) as average_interest_rate
from "casestudy"."intermediate"."stg_staging_intermediate__customers" c
left join accounts a on c.customer_id = a.customer_id
left join transactions t on c.customer_id = t.customer_id
left join loans l on c.customer_id = l.customer_id
    );
  
  