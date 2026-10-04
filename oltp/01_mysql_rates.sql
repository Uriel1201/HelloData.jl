WITH
    TOTALS("USER_ID", "TOTAL_STARTS", "TOTAL_CANCELS", "TOTAL_PUBLISHES") AS (
        SELECT 
            "USER_ID",
            SUM(
                CASE
                    WHEN "ACTION" = 'start'
                    THEN 1
                    ELSE 0
                END
            ),
            SUM(
                CASE
                    WHEN "ACTION" = 'cancel'
                    THEN 1
                    ELSE 0
                END
            ),
            SUM(
                CASE
                    WHEN "ACTION" = 'publish'
                    THEN 1
                    ELSE 0
                END
            )
        FROM
            USERS_01
        GROUP BY
            "USER_ID"
    )
SELECT 
    "USER_ID",
    ROUND("TOTAL_PUBLISHES" / CASE
              WHEN "TOTAL_STARTS" = 0
              THEN NULL
              ELSE "TOTAL_STARTS"
          END, 3) AS "PUBLISH_RATES",
    ROUND("TOTAL_CANCELS" / CASE
              WHEN "TOTAL_STARTS" = 0
              THEN NULL
              ELSE "TOTAL_STARTS"
          END, 3) AS "CANCEL_RATES"
FROM
    TOTALS
