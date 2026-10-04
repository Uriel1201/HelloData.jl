with positions (
    user_id,
    dates,
    position 
) as (
    select 
        "ID",
        "ACTION_DATE"::date,
        row_number() over(
            partition by
                "ID"
            order by "ACTION_DATE" desc
        )
    from
        "USERS_04"
    where 
        "ACTION_DATE" is not null
), last (
    user_id,
    dates
) as (
    select
        positions.user_id,
        positions.dates
    from
        positions 
    where
        positions.position = 1
), second_last (
    user_id,
    dates
) as (
    select
        positions.user_id,
        positions.dates
    from
        positions 
    where
        positions.position = 2
)
select
    last.user_id,
    (last.dates - second_last.dates) as days_elapsed
from
    last
    left outer join second_last on last.user_id = second_last.user_id
