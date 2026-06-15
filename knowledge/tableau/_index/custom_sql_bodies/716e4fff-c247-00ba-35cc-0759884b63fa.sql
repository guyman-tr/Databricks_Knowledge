SELECT 
CASE WHEN a.Regulation IN ('ASIC', 'ASIC & GAML') THEN 'ASIC + ASICGAML' ELSE a.Regulation END AS Regulation
,a.RiskScoreName
,COUNT(a.CID) AS Count_CIDs
FROM de_output.de_output_risk_classification a
GROUP BY a.Regulation, a.RiskScoreName