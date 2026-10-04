WITH
    users (user_id, action, action_date) AS (
        SELECT 
            user_id,
            NULLIF(TRIM(action), ''),
            action_date
        FROM
            users_01
    ),
    totals (user_id, total_starts, total_cancels, total_publishes) AS (
        SELECT 
            users.user_id,
            1.0 * SUM(1) FILTER(WHERE users.action = 'start'),
            1.0 * COUNT(*) FILTER(WHERE users.action = 'cancel'),
            1.0 * COUNT(*) FILTER(WHERE users.action = 'publish')
        FROM
            users
        WHERE 
            users.action <> 'NaN'
            AND users.action_date IS NOT NULL
        GROUP BY
            users.user_id
    )
SELECT 
    totals.user_id,
    ROUND(totals.total_publishes / totals.total_starts
        ,2) as publish_rate,
    round(totals.total_cancels / totals.total_starts
        ,2) as cancel_rate
FROM
    totals
