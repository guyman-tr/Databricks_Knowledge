SELECT * from (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY CID, AlertType, AlertDate
            ORDER BY AlertID
        ) AS rn
    FROM [BI_DB_dbo].[BI_DB_AML_BI_Alerts_New_Singapore]
    WHERE AlertDate >= '2025-07-01'
) cte

WHERE rn = 1