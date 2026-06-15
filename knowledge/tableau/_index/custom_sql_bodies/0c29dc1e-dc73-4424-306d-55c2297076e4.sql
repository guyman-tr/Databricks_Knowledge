SELECT	dc.GCID,
		dc.RealCID,
        dc.IsValidCustomer,
		dc1.MarketingRegionManualName [Region],
		dc1.Name [Country],
		dr.Name [Regulation],
		dr1.Name [DesignatedRegulation],
		CASE WHEN dc.CountryID <> dc.CountryIDByIP AND dc.VerificationLevelID <> 3 THEN 1 ELSE 0 END [PotentialBot],
		dc2.Channel,
		dc2.SubChannel,
		dc.RegisteredReal [RegistrationDate],
		bdcd.VerificationLevel1Date,
		bdcd.VerificationLevel2Date,
		bdcd.VerificationLevel3Date,
		bdcd.Verified,
		CASE WHEN bdcd.FirstDepositDate >= bdcd.registered THEN DATEDIFF(DAY, bdcd.registered, bdcd.FirstDepositDate) ELSE NULL END [RegToFTD_GapInDays],
		DATEDIFF(DAY, bdcd.registered, bdcd.VerificationLevel1Date) [RegToV1_GapInDays],
		DATEDIFF(DAY, bdcd.VerificationLevel1Date, bdcd.VerificationLevel2Date) [V1ToV2_GapInDays],
		DATEDIFF(DAY, bdcd.VerificationLevel2Date, bdcd.VerificationLevel3Date) [V2ToV3_GapInDays],
		DATEDIFF(DAY, bdcd.registered, bdcd.VerificationLevel3Date) [RegToV3_GapInDays],
		bdcd.FirstDepositAttempt,
		bdcd.FirstDepositDate,
		bdcd.FirstDepositAmount,
		CASE WHEN bdcd.FirstDemoLoggedIn IS NOT NULL OR YEAR(bdcd.FirstDemoLoggedIn) >= 2007 THEN 1 ELSE 0 END [Demo_LoggedIn],
		bdcd.FirstDemoLoggedIn,
		bdcd.EmailVerifiedDate,
		bdcd.PhoneVerifiedDate,
		bdcd.FunnelName,
		bdcd.Gender,
		bdcd.PopularInvestor,
		bdcd.Blocked
FROM DWH_dbo.Dim_Customer dc
LEFT JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdcd ON dc.GCID = bdcd.GCID
LEFT JOIN DWH_dbo.Dim_Regulation dr ON dc.RegulationID = dr.DWHRegulationID
LEFT JOIN DWH_dbo.Dim_Regulation dr1 ON dc.DesignatedRegulationID = dr1.DWHRegulationID
LEFT JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID = dc1.CountryID
LEFT JOIN DWH_dbo.Dim_Channel dc2 ON dc.SubChannelID = dc2.SubChannelID
WHERE 
    YEAR(dc.RegisteredReal) >= 2023