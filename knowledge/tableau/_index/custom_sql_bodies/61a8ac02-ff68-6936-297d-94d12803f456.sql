SELECT 
	dc.RealCID, 
	dc.GCID,
	dc.AffiliateID,
	da.Contact AS AffiliateName,
	dc.SubSerialID,
	dc.CampaignID, 
	dc2.[Description] AS CampaignDescription,
	dc1.Name AS Country,
	dr.Name AS Regulation,
	dr1.Name AS DesignatedRegulation,
	dc.VerificationLevelID,
	dc.RegisteredReal AS Registration_DateTime,
	CAST(dc.RegisteredReal AS DATE) AS Registration_Date,

	bdcd.VerificationLevel3Date AS V3_DateTime,
	CAST(bdcd.VerificationLevel3Date AS DATE) AS V3_Date,

	CASE WHEN YEAR(dc.FirstDepositDate) = 1900 THEN NULL ELSE dc.FirstDepositDate END AS FirstDepositDateTime,
	CASE WHEN YEAR(dc.FirstDepositDate) = 1900 THEN NULL ELSE CAST(dc.FirstDepositDate AS DATE) END AS FirstDepositDate,
	
	CASE WHEN dc.FirstDepositAmount IS NULL THEN 0 ELSE dc.FirstDepositAmount END AS FirstDepositAmount,
	CASE WHEN dc.FirstDepositAmount IS NOT NULL THEN 1 ELSE 0 END AS Made_FTD,
	dps.Name AS PlayerStatus,
	CAST(GETDATE() AS DATE) AS UpdateDate
FROM
	DWH_dbo.Dim_Customer dc
	LEFT JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdcd ON dc.RealCID = bdcd.CID
	JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID = dc1.CountryID
	JOIN DWH_dbo.Dim_Regulation dr ON dc.RegulationID = dr.ID
	JOIN DWH_dbo.Dim_Regulation dr1 ON dc.DesignatedRegulationID = dr1.ID
	JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID
	JOIN DWH_dbo.Dim_Manager dm ON dc.AccountManagerID = dm.ManagerID
	JOIN DWH_dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
	JOIN DWH_dbo.Dim_Affiliate da ON dc.AffiliateID = da.AffiliateID
	JOIN DWH_dbo.Dim_Campaign dc2 ON dc.CampaignID = dc2.CampaignID
WHERE
	1=1
	AND dc.AffiliateID = 119788
	AND dpl.Name <> 'Internal'
	AND dc.IsValidCustomer =1
	AND CAST(dc.RegisteredReal AS DATE) >= CAST('2025-11-29' AS DATE) -- program starts 29 Nov 2025