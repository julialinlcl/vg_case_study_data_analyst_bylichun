
  
    
    

    create  table
      "casestudy"."marts"."mart_customer__summary__dbt_tmp"
  
    as (
      with customer_data as (
    select
        c.customer_id,
        c.age,
        c.firstname,
        c.lastname,
        c.branch_id,
        case
            when c.age between 18 and 25 then '18-25'
            when c.age between 26 and 35 then '26-35'
            when c.age between 36 and 45 then '36-45'
            when c.age between 46 and 60 then '46-60'
            else '60+'
        end as age_group,
        c.gender
    from "casestudy"."intermediate"."stg_staging_intermediate__customers" c
),

loan_data as (
    select
        customer_id,
        loan_type,
        date_trunc('month', approval_rejection_date) as approval_month
    from "casestudy"."intermediate"."stg_staging_intermediate__loans"
    where loan_status = 'approved' 
        and approval_rejection_date is not null
),

account_data as (
    select
        customer_id,
        account_type
    from "casestudy"."intermediate"."stg_staging_intermediate__accounts"
),

transaction_data as (
    select
        a.customer_id,
        t.transaction_type,
        date_trunc('month', t.transaction_date) as transaction_month
    from "casestudy"."intermediate"."stg_staging_intermediate__transactions" t
    join "casestudy"."intermediate"."stg_staging_intermediate__accounts" a
        on t.account_id = a.account_id
)

select
    cd.age_group,
    cd.gender,
    ad.account_type,
    ld.loan_type,
    ld.approval_month,
    td.transaction_type,
    td.transaction_month,
    count(distinct cd.customer_id) as customer_count
from customer_data cd
left join loan_data ld on cd.customer_id = ld.customer_id
left join account_data ad on cd.customer_id = ad.customer_id
left join transaction_data td on cd.customer_id = td.customer_id
group by 1, 2, 3, 4, 5, 6, 7
    );
  
  