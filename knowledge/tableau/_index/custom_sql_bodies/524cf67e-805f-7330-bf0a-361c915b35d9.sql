SELECT *
FROM (
    WITH status_changes AS (
        SELECT
            fsc.RealCID AS CID,
            fsc.PlayerStatusID AS Current_Status_ID,
            dps.Name AS Current_Status,
            LAG(fsc.PlayerStatusID) OVER (
                PARTITION BY fsc.RealCID 
                ORDER BY dr.FromDateID
            ) AS Previous_Status_ID,
            TO_TIMESTAMP(CAST(dr.FromDateID AS STRING), 'yyyyMMdd') AS Change_Timestamp
        FROM
            main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
        INNER JOIN
            main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
            ON fsc.DateRangeID = dr.DateRangeID
        LEFT JOIN
            main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus dps
            ON fsc.PlayerStatusID = dps.PlayerStatusID
        WHERE
            fsc.IsValidCustomer = 1
            AND TO_DATE(CAST(dr.FromDateID AS STRING), 'yyyyMMdd')
                >= ADD_MONTHS(CURRENT_DATE(), -6)
    ),
    filtered_changes AS (
        SELECT *
        FROM status_changes
        WHERE Current_Status_ID <> Previous_Status_ID
    ),
    limited_events AS (
        SELECT
            CID,
            Change_Timestamp AS Limited_Timestamp,
            Current_Status_ID,
            Current_Status AS Limitation_Type
        FROM filtered_changes
        WHERE Current_Status_ID NOT IN (1)
    ),
    normal_events AS (
        SELECT
            CID,
            Change_Timestamp AS Normal_Timestamp
        FROM filtered_changes
        WHERE Current_Status_ID IN (1)
    ),
    paired_events AS (
        SELECT
            l.CID,
            l.Limitation_Type,
            l.Limited_Timestamp,
            MIN(n.Normal_Timestamp) AS First_Normal_Timestamp
        FROM limited_events l
        JOIN normal_events n
            ON l.CID = n.CID
            AND n.Normal_Timestamp > l.Limited_Timestamp
        GROUP BY
            l.CID,
            l.Limitation_Type,
            l.Limited_Timestamp
    )
    SELECT
        CID,
        Limitation_Type,
        Limited_Timestamp,
        First_Normal_Timestamp,
        TIMESTAMPDIFF(HOUR, Limited_Timestamp, First_Normal_Timestamp) AS Hours_To_Normal,
        DATEDIFF(First_Normal_Timestamp, Limited_Timestamp) AS Days_To_Normal
    FROM paired_events
    WHERE First_Normal_Timestamp IS NOT NULL
)