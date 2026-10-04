with transactions (
    sender,
    receiver,
    amount
) as (
    select
        "SENDER",
        "RECEIVER",
        "AMOUNT"::decimal
    from
        "TRANSACTIONS_02"
    where
        "AMOUNT" is not null
), senders (
    user_id,
    amount
) as (
    select
        transactions.sender,
        sum(transactions.amount)
    from
        transactions 
    group by 
        transactions.sender
), receivers (
    user_id,
    amount
) as (
    select
        transactions.receiver,
        sum(transactions.amount)
    from
        transactions 
    group by
        transactions.receiver
)    
select 
    coalesce(senders.user_id, receivers.user_id) as user_id,
    -1.0*(coalesce(senders.amount, 0) - coalesce(receivers.amount, 0)) as net_changes
from
    senders
    full outer join receivers on senders.user_id = receivers.user_id
