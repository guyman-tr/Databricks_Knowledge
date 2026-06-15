SELECT *  from eMoney_dbo.eMoney_Dim_Account mda
where mda.GCID_Unique_Count=1 and mda.IsValidETM=1 and mda.IsTestAccount=0 
AND mda.AccountSubProgramID IN (13,14)