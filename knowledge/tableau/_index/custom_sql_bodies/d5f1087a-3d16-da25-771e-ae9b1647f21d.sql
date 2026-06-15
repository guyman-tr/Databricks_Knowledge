SELECT dr.ID RegulationID,
dr.Name RegulationName
FROM DWH_dbo.Dim_Regulation dr
UNION ALL 
SELECT TOP 1 -1 AS RegulationID,
'All' AS [RegulationName]
FROM DWH_dbo.Dim_Regulation