SELECT 
    aa.CID,
    aa.min_InstanceActivationDate,
    aa.active_months_count,
    aa.active_weeks_count,
    aa.AccountSubProgram,
    aa.total_months_since_activation,
    aa.total_weeks_since_activation,
    aa.is_monthly_usage,
    aa.is_weekly_usage,
    bb.CID AS CID_That_Has_Active_Card_Today,
    bb.InstanceStatus AS CIDs_Status_Of_Current_Card,
    bb.DWH_CardInstanceId AS CurrentlyActive_CardInstanceId
FROM (
    SELECT 
        base.CID,
        base.min_InstanceActivationDate,
        base.active_months_count,
        base.active_weeks_count,
        base.AccountSubProgram,
        
        -- Total months since activation (inclusive)
        DATEDIFF(MONTH, base.min_InstanceActivationDate, CAST(GETDATE() AS DATE)) + 1 
            AS total_months_since_activation,

        -- Total weeks since activation (inclusive)
        DATEDIFF(WEEK, base.min_InstanceActivationDate, CAST(GETDATE() AS DATE)) + 1 
            AS total_weeks_since_activation,

        -- Monthly usage flag
        CASE 
            WHEN base.active_months_count = DATEDIFF(MONTH, base.min_InstanceActivationDate, CAST(GETDATE() AS DATE)) + 1 
            THEN 1 ELSE 0 
        END AS is_monthly_usage,

        -- Weekly usage flag
        CASE 
            WHEN base.active_weeks_count = DATEDIFF(WEEK, base.min_InstanceActivationDate, CAST(GETDATE() AS DATE)) + 1 
            THEN 1 ELSE 0 
        END AS is_weekly_usage

    FROM (
        SELECT 
            s.CID, 
            MIN(s.InstanceActivationDate) AS min_InstanceActivationDate,
            MAX(mda.AccountSubProgram) AS AccountSubProgram,
            COUNT(DISTINCT FORMAT(mdt.TxStatusModificationDate, 'yyyy-MM')) AS active_months_count,
            COUNT(
                DISTINCT DATENAME(week, mdt.TxStatusModificationDate) 
                + '-' 
                + DATENAME(year, mdt.TxStatusModificationDate)
            ) AS active_weeks_count
        FROM eMoney_dbo.eMoney_Card_Instance_Summary s 
        JOIN eMoney_dbo.eMoney_Dim_Account mda
            ON s.CID = mda.CID 
            AND mda.GCID_Unique_Count = 1 
            AND mda.IsValidETM = 1 
        LEFT JOIN (
            SELECT * 
            FROM eMoney_dbo.eMoney_Dim_Transaction a WITH (NOLOCK) 
            WHERE a.IsValidETM = 1 
              AND a.IsTxSettled = 1 
              AND a.TxTypeID IN (1,2,3,4,13)
        ) mdt  
            ON s.CID = mdt.CID  
            AND mdt.TxStatusModificationDate >= s.InstanceActivationDate 
        GROUP BY s.CID 
    ) base
) aa 
LEFT JOIN (
    SELECT 
        mcis.CID, 
        mcis.InstanceStatus, 
        mcis.DWH_CardInstanceId 
    FROM eMoney_dbo.eMoney_Card_Instance_Summary mcis
    WHERE mcis.InstanceStatus = 'Activated'
) bb 
    ON aa.CID = bb.CID