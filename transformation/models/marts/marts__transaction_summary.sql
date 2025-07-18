with transaction_data as (
    select
        t.account_id,
        a.customer_id,
        t.transaction_amount,
        t.transaction_date,
        t.transaction_type
    from {{ ref('stg_staging_intermediate__transactions') }} t
    join {{ ref('stg_staging_intermediate__accounts') }} a
      on t.account_id = a.account_id
),
aggregated as (
    select
        customer_id,
        account_id,
        sum(transaction_amount) as total_transaction_amount,
        count(*) as transaction_count,
        min(transaction_date) as first_transaction_date,
        max(transaction_date) as last_transaction_date,
        mode() within group (order by transaction_type) as most_common_transaction_type
    from transaction_data
    group by customer_id, account_id
)
select * from aggregated
