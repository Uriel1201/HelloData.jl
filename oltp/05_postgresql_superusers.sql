with users (
    user_id
) as (
    select distinct 
        "USER_ID"
    from 
        "USERS_05"
), transactions (
    user_id,
    dates,
    position 
) as (
    select 
        "USER_ID",
        "TRANSACTION_DATE"::date,
        row_number() over (
            partition by "USER_ID"
            order by "TRANSACTION_DATE"
        )
    from 
        "USERS_05"
), supers (
    user_id,
    date_as_super
) as (
    select 
        transactions.user_id,
        transactions.dates
    from 
        transactions 
    where 
        transactions.position = 2
)
select 
    users.user_id,
    supers.date_as_super
from
    users
    left join supers on users.user_id = supers.user_id
