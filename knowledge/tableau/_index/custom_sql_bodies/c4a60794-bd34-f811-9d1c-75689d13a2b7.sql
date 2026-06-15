SELECT DISTINCT 
	Table_Name
FROM [dbo].[DWH_Compare_Results_new_compare_Diff_View] a
where a.DateID < CAST(CONVERT(VARCHAR(8), getdate(), 112) AS INT)