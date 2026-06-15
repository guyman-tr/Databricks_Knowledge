SELECT 
        amt.CID, 
        amt.AlertType, 
        COUNT(*) AS AlertCount,
        MAX(amt.AlertDate) AS LatestBIAlertDate
    FROM BI_DB_dbo.BI_DB_AML_BI_Alerts_New amt
    GROUP BY  amt.CID, amt.AlertType