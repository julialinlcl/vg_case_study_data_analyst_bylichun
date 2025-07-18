
  
    
    

    create  table
      "casestudy"."marts"."marts__currency_usage__dbt_tmp"
  
    as (
      select
    t.transaction_currency as currency_iso_code,
    c.currency as currency_name,
    count(*) as transaction_count,
    sum(t.transaction_amount) as total_transaction_amount
from "casestudy"."intermediate"."stg_staging_intermediate__transactions" t
left join "casestudy"."intermediate"."stg_staging_intermediate__currencies" c
  on t.transaction_currency = c.currency_iso_code
group by t.transaction_currency, c.currency
    );
  
  