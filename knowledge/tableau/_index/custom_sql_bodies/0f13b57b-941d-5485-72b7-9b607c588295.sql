SELECT *
FROM eMoney_dbo.eMoney_Dim_Account mda
WHERE mda.IsValidETM=1 AND mda.GCID_Unique_Count=1