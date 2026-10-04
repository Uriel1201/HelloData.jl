with 
    users ("USER_ID", "ACTION", "DATES") as (
        select
            "USER_ID",
            nullif(trim("ACTION"), ''),
            nullif(trim("DATES"), '')::date
        from
            "USERS_01"
    ),
    totals ("USER_ID", "TOTAL_STARTS", "TOTAL_CANCELS", "TOTAL_PUBLISHES") as (
        select 
            users."USER_ID",
            sum(
                case
                    when users."ACTION" = 'start'
                    then 1
                    else 0
                end
            )::numeric,
            sum(
                case
                    when users."ACTION" = 'cancel'
                    then 1
                    else 0
                end
            )::numeric,
            sum(
                case
                    when users."ACTION" = 'publish'
                    then 1
                    else 0
                end
            )::numeric
        from
            users
        where
            users."DATES" is not null
            and users."ACTION" <> 'NaN'
        group by
            users."USER_ID"
    )
select 
    totals."USER_ID",
    round(totals."TOTAL_PUBLISHES" / case
              when totals."TOTAL_STARTS" = 0
              then null
              else totals."TOTAL_STARTS"
          end, 2) as "PUBLISH_RATES",
    round(totals."TOTAL_CANCELS" / case
              when totals."TOTAL_STARTS" = 0
              then null
              else totals."TOTAL_STARTS"
          end, 2) as "CANCEL_RATES"
from
    totals
