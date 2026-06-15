SELECT 
    v.*, 
    COALESCE(a.AlertTypes, 'No Alerts') AS AlertTypes
FROM BI_DB_dbo.BI_DB_OPS_VerificationLevel2Stuck v
LEFT JOIN (
    SELECT 
        CID, 
        STRING_AGG(AlertType, ', ') AS AlertTypes
    FROM (
        SELECT DISTINCT CID, AlertType
        FROM BI_DB_dbo.BI_DB_RiskAlertManagementTool
        WHERE StatusType IN ('Active', 'Follow Up')
    ) AS DistinctAlerts
    GROUP BY CID
) a ON v.CID = a.CID