-- ============================================
-- 1. POP: Build the player's status change log
-- ============================================
WITH pop AS (
    SELECT
        a.CID,
        a.PlayerStatusID AS Current_ID,
        dps.Name AS Current_PlayerStatus,
        a.Previous_PlayerStatusID AS Previous_ID,
        pps.Name AS Previous_PlayerStatus,
        a.Change_Date

    FROM (
        SELECT 
            fsc.RealCID AS CID,
            fsc.PlayerStatusID,
            fsc.PlayerStatusReasonID,
            fsc.PlayerStatusSubReasonID,
            TO_DATE(CAST(dr.FromDateID AS STRING), 'yyyyMMdd') AS Change_Date,
            LAG(fsc.PlayerStatusID) OVER (PARTITION BY fsc.RealCID ORDER BY dr.FromDateID ASC) AS Previous_PlayerStatusID
        FROM 
            dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
        INNER JOIN 
            main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr  ON fsc.DateRangeID = dr.DateRangeID
        WHERE 
            fsc.IsValidCustomer = 1
            AND fsc.IsDepositor = 1
    ) a

    LEFT JOIN 
        dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus dps ON a.PlayerStatusID = dps.PlayerStatusID
    LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus pps ON a.Previous_PlayerStatusID = pps.PlayerStatusID
    WHERE 
        a.PlayerStatusID <> a.Previous_PlayerStatusID
        AND a.Change_Date >= DATEADD(month, -12, current_date())
),

-- =======================================
-- 2. FIRST time limited (9,10,15)
-- =======================================
first_limited AS (
    SELECT
        CID,
        Change_Date AS FirstLimitedDate,
        Current_ID,
        Current_PlayerStatus AS FirstLimitedStatus,
        ROW_NUMBER() OVER (PARTITION BY CID ORDER BY Change_Date ASC) AS rn
    FROM pop
    WHERE Current_ID IN (9,10,13,15) -- Limited Statuses
),

-- =======================================
-- 3. LAST overall status (not limited-only)
-- =======================================
last_status AS (
    SELECT
        CID,
        Change_Date AS LastStatusDate,
        Current_ID,
        Current_PlayerStatus AS LastStatus,
        ROW_NUMBER() OVER (PARTITION BY CID ORDER BY Change_Date DESC) AS rn
    FROM pop
),

-- =======================================
-- 4. Limited events
-- =======================================
limited_events AS (
    SELECT
        CID,
        COUNT(*) AS LimitedEventsCount
    FROM pop
    WHERE Current_ID IN (9,10,13,15)
    GROUP BY CID
)


-- =======================================
-- 5. FINAL OUTPUT — ONE ROW PER CID
-- =======================================

SELECT
    f.CID,
    f.FirstLimitedDate,
    f.FirstLimitedStatus,
    l.LastStatusDate as LastPlayerStatusChangeDate,
    l.LastStatus as CurrentPlayerStatus,
    DATEDIFF(l.LastStatusDate, f.FirstLimitedDate) AS DaysBetweenLimitedAndLast,
    CASE
        WHEN l.Current_ID IN (9,10,13,15) THEN 'Still Limited'
        WHEN l.Current_ID IN (2,4) THEN 'Limited to Blocked'
        WHEN l.Current_ID IN (1,5,12) THEN 'Limited to Normal'
        ELSE 'Other'
    END AS Limitation_Category,
    e.LimitedEventsCount,
    (li.Liabilities + li.ActualNWA) AS Equity,
    c.VerificationLevelID,
    psr.Name as Current_PlayerStatusReason,
    pssr.PlayerStatusSubReasonName as Current_PlayerStatusSubReason,
    pl.Name as Current_PlayerLevel,
    r.Name as Regulation,
    pcs.PendingClosureStatusName
FROM 
    first_limited f
JOIN 
    last_status l  ON f.CID = l.CID
LEFT JOIN 
    limited_events e ON e.CID = f.CID
LEFT JOIN
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities li on li.CID = f.CID and li.DateID = date_format(date_sub(current_date(), 1), 'yyyyMMdd')
LEFT JOIN
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked c on c.RealCID = f.CID
LEFT JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr on psr.PlayerStatusReasonID = c.PlayerStatusReasonID
LEFT JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons pssr on pssr.PlayerStatusSubReasonID = c.PlayerStatusSubReasonID
LEFT JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl on c.PlayerLevelID = pl.PlayerLevelID
LEFT JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r on r.ID = c.RegulationID
LEFT JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus pcs on pcs.PendingClosureStatusID = c.PendingClosureStatusID
WHERE 
    f.rn = 1     -- first time limited
    AND l.rn = 1     -- last status overall
    --and f.cid = 45412382