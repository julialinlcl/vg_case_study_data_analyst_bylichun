
  
    
    

    create  table
      "casestudy"."intermediate"."stg_staging_intermediate__currencies__dbt_tmp"
  
    as (
      with staging as (
    select * from "casestudy"."raw"."currencies"
),
cleaned as (
    select distinct
        trim(regexp_replace(currency, '\\[.*\\]', '')) as currency,
        
        case 
            when upper(trim(currency_iso_code)) = 'USDOL' then 'USD'
            when upper(trim(currency_iso_code)) = '(NONE)' then null
            else upper(trim(currency_iso_code))
        end as currency_iso_code
    from staging
    where currency_iso_code is not null and trim(currency_iso_code) != '(none)'
)

select * from cleaned
    );
  
  