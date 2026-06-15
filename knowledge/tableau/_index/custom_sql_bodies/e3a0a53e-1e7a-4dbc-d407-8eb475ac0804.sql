SELECT 
	mda.CID,
	mda.AccountCreateDate,
	fsc.PlayerLevelID,
	dpl.Name AS club_at_iban_account_created_date
FROM eMoney_dbo.eMoney_Dim_Account mda
INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc
	ON mda.CID = fsc.RealCID
INNER JOIN DWH_dbo.Dim_Range dr
	ON dr.DateRangeID = fsc.DateRangeID
	AND mda.AccountCreateDateID BETWEEN dr.FromDateID AND dr.ToDateID
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl
	ON fsc.PlayerLevelID = dpl.PlayerLevelID
WHERE mda.GCID_Unique_Count = 1
	AND mda.IsValidETM = 1
	AND mda.IsTestAccount = 0
	AND mda.AccountSubProgramID IN (13, 14)