with items (
    items,
    dates
) as (
    select
        nullif(trim("ITEM"), '') as items,
        "DATES"::date as dates
    from
        "ITEMS_03"
), frequencies (
    items,
    frequency,
    dates
) as (
    select
        items.items,
        count(*),
        items.dates
    from
        items
    where
        items.items <> 'NaN'
    group by
        items.dates, items.items
), ranked_items (
    items,
    position,
    dates
) as (
    select 
        frequencies.items,
        rank() over(
            partition by frequencies.dates
            order by frequencies.frequency desc
        ),
        frequencies.dates
    from
        frequencies 
)
select 
    ranked_items.items,
    ranked_items.dates
from
    ranked_items
where
    ranked_items.position = 1
