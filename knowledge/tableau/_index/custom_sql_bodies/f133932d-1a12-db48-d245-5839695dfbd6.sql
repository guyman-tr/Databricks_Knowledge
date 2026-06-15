SELECT bdon.*, CASE WHEN vgbf.CID IS NOT NULL THEN 1 ELSE 0 END AS IsGermanBaFin
FROM BI_DB_dbo.BI_DB_Outliers_New bdon with (nolock)
	LEFT JOIN BI_DB_dbo.V_GermanBaFin vgbf
		ON bdon.DateID = vgbf.DateID
		   AND bdon.RealCID = vgbf.CID
WHERE bdon.DateID between 
CAST(CONVERT(VARCHAR(10), CAST(<[Parameters].[ToDateID (copy)]> as DATE), 112) AS INT)
and 
CAST(CONVERT(VARCHAR(10), CAST(<[Parameters].[ToDateID (copy 2)]> as DATE), 112) AS INT)