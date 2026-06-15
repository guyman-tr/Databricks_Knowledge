SELECT 
	bdcclp.*,
	dc.VerificationLevelID,
	dc1.MarketingRegionManualName [MarketingRegion],
	dc1.Name [Country],

	YEAR(dc.RegisteredReal) [Reg_Year],
	CAST(dc.RegisteredReal AS DATE) [Reg_Date],
	CAST(bdcd.VerificationLevel3Date AS DATE) [V3_Date],
	CAST(bdcd.FirstDepositDate AS DATE) [FTD_Date],
	CAST(bdcclp.Date AS DATE) [FTC_Date],

	DATEDIFF(DAY, dc.RegisteredReal, bdcclp.Date) [Days_RegtoFTC],
	DATEDIFF(DAY, bdcd.VerificationLevel3Date, bdcclp.Date) [Days_V3toFTC],
	DATEDIFF(DAY, bdcd.FirstDepositDate, bdcclp.Date) [Days_FTDtoFTC],
	CASE WHEN fca.CompensationReasonID = 99 THEN 1 ELSE 0 END AS [ReceivedAirdrop],
	fca.Amount [Airdrop_Amount],
	CAST(fca.Occurred AS DATE) [Airdrop_Date]

FROM 
	BI_DB_dbo.BI_DB_ClubChangeLogProduct bdcclp
	JOIN DWH_dbo.Dim_Customer dc ON bdcclp.CID = dc.RealCID
	JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID = dc1.CountryID
	JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdcd ON bdcclp.CID = bdcd.CID
	LEFT JOIN DWH_dbo.Fact_CustomerAction fca ON bdcd.CID = fca.RealCID AND fca.CompensationReasonID = 99 /*airdrop action*/
WHERE
	1=1
--	dc1.MarketingRegionManualName IN ('SEA','Australia')
	AND bdcclp.IsFTC = 1
	AND YEAR(bdcclp.Date) = 2024 /*Clients who FTC in 2024 */
	AND YEAR(dc.RegisteredReal) IN (2023, 2024) /* Clients who registered in 2023 & 2024*/
	AND bdcd.UserName NOT LIKE '%test%' 
	AND bdcd.UserName NOT LIKE '%Test%'
	AND bdcd.FirstDepositDate IS NOT NULL /*Clients who made their FTD*/