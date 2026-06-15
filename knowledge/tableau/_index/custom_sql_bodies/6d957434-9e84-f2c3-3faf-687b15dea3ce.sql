SELECT 
CASE WHEN a.Regulation IN ('ASIC', 'ASIC & GAML') THEN 'ASIC + ASICGAML' ELSE a.Regulation END AS 'Regulation'
,a.RiskScoreName
,COUNT(a.CID) AS 'Count_CIDs'
FROM BI_DB.dbo.BI_DB_RiskClassification a
GROUP BY a.Regulation, a.RiskScoreName