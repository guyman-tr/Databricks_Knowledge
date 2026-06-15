SELECT 
    base.CID,
    FORMAT(CAST(CONVERT(varchar(8), base.Report_Date_ID) AS date), 'yyyyMM') AS Report_Month,
    
    -- Get most recent cluster per client/month
    (
        SELECT TOP 1 b2.CO_Cluster
        FROM BI_DB_dbo.BI_DB_CO_Cluster_Daily b2
        WHERE b2.CID = base.CID
          AND FORMAT(CAST(CONVERT(varchar(8), b2.Report_Date_ID) AS date), 'yyyyMM') = 
              FORMAT(CAST(CONVERT(varchar(8), base.Report_Date_ID) AS date), 'yyyyMM')
        ORDER BY b2.CO_Last_Transaction DESC
    ) AS Last_CO_Cluster,

    -- Monthly CO amount per client
    SUM(base.Daily_CO_Amount) AS Monthly_CO_Amount

FROM (
    SELECT 
        bdcdd.CID,
        bdcdd.Report_Date_ID,
        bdcdd.CO_Last_Transaction,
        ISNULL(x.Daily_CO_Amount, 0) AS Daily_CO_Amount
    FROM BI_DB_dbo.BI_DB_CO_Cluster_Daily bdcdd
    LEFT JOIN (
        SELECT 
            fca.RealCID, 
            fca.DateID, 
            SUM(fca.Amount) AS Daily_CO_Amount
        FROM DWH_dbo.Fact_CustomerAction fca
        WHERE fca.ActionTypeID = 8
          AND fca.DateID BETWEEN 20240101 AND 20250701
        GROUP BY fca.RealCID, fca.DateID
    ) x ON x.RealCID = bdcdd.CID AND x.DateID = bdcdd.Report_Date_ID
) base

GROUP BY 
    base.CID,
    FORMAT(CAST(CONVERT(varchar(8), base.Report_Date_ID) AS date), 'yyyyMM')