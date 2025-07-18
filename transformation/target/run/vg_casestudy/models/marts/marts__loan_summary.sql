
  
    
    

    create  table
      "casestudy"."marts"."marts__loan_summary__dbt_tmp"
  
    as (
      with loan_data as (
    select *
    from "casestudy"."intermediate"."stg_staging_intermediate__loans"
),
aggregated as (
    select
        customer_id,
        count(*) as total_loans,
        sum(loan_amount) as total_loan_amount,
        avg(interest_rate) as average_interest_rate,
        count(case when loan_status = 'approved' then 1 end) as active_loans_count,
        count(case when loan_status = 'closed' then 1 end) as closed_loans_count,
        max(approval_rejection_date) as latest_loan_date,
        avg(loan_term) as average_loan_term
    from loan_data
    group by customer_id
)
select *,
       case
           when closed_loans_count > 0 then 'closed'
           when active_loans_count > 0 then 'approved'
           else 'rejected'
       end as latest_loan_status
from aggregated
    );
  
  