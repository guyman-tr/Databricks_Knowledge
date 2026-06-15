SELECT 
	dc.RealCID
	,CONCAT(dc.FirstName, ' ', dc.LastName) AS FullName
	,dat.Name AS AccountType
	,dc1.Name AS Country
	,CAST(fd.VerificationLevel3Date AS DATE) AS VerificationLevel3Date
        ,CAST(fd.VerificationLevel1Date AS DATE) AS VerificationLevel1Date
        ,CAST(fd.VerificationLevel2Date AS DATE) AS VerificationLevel2Date
	,da.AffiliateID
        ,dc.VerificationLevelID
	,da.TradingAccount_RealCID
	,dss.Name AS ScreeningStatus
FROM DWH_dbo.Dim_Customer dc
LEFT JOIN DWH_dbo.Dim_AccountType dat ON dat.AccountTypeID = dc.AccountTypeID
LEFT JOIN DWH_dbo.Dim_Country dc1 ON dc1.CountryID = dc.CountryID
LEFT JOIN BI_DB_dbo.BI_DB_CIDFirstDates fd ON fd.CID = dc.RealCID
LEFT JOIN DWH_dbo.Dim_Affiliate da ON da.GCID = dc.GCID
LEFT JOIN DWH_dbo.Dim_ScreeningStatus dss ON dss.ScreeningStatusID = dc.ScreeningStatusID
WHERE 
	dc.AccountTypeID IN (6,15) -- Affiliate Private and Affiliate Corporate