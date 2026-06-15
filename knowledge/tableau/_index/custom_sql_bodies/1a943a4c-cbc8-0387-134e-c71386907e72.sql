SELECT  bdlp.*,bdlrm.RatioSnapshotTo8Y
FROM BI_DB_dbo.BI_DB_LTV_Predictions bdlp
INNER JOIN BI_DB_dbo.BI_DB_LTV_Revenue_Multipliers bdlrm ON 
bdlp.Seniority=bdlrm.Seniority AND bdlp.MonthsSinceLastPosOpen=bdlrm.MonthsSinceLastActive 
AND bdlrm.Date='2024-04-30'