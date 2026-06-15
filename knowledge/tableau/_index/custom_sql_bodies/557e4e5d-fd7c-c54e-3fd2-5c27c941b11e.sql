SELECT 
    r.Comment,
    r.AlertType,
    r.ModifiedBy,
    CAST(r.CreationDate AS date) AS CreationDate,
    CASE 
        WHEN r.ModifiedBy = 0 AND r.Comment LIKE '%Automatic checks failed%' 
            THEN 'Pending Manual Review'
        WHEN r.ModifiedBy = 0 AND r.Comment LIKE '%No action needed%' 
            THEN 'Autocleared'
        WHEN r.ModifiedBy <> 0 
            THEN 'Manually Reviewed'
    END AS AI_Results,
    COUNT(r.AlertID) AS totalalerts
FROM main.bi_output_stg.bi_output_operations_risk_alert_management_tool r
WHERE 
(
        r.AlertType = 'BinToRegCountryConflict'
        AND r.CreationDate >= '2026-01-19 16:00'
    )
    OR
    (
        r.AlertType = 'HighCORedeem'
        AND r.CreationDate >= '2025-12-15'
    )
	OR
    (
        r.AlertType = 'RiskRelations'
        AND r.CreationDate >= '2026-01-19 16:00'
    )
GROUP BY 
    r.Comment,
    r.AlertType,
    r.ModifiedBy,
    CAST(r.CreationDate AS date)