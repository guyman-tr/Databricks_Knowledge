SELECT a.NewMarketingRegion [MarketingRegion],
	a.Country,
	a.Regulation,
	a.DesignatedRegulation,
	a.Registration_Date,
	a.Reg_Channel,
	a.Reg_SubChannel,
	a.PotentialBot,
	SUM(a.Reg_Complete) [Reg_Complete],
	SUM(a.V1_Complete) [V1_Complete],
	SUM(a.V2_Complete) [V2_Complete],
	SUM(a.V3_Complete) [V3_Complete],
	SUM(a.FTDA_Complete) [FTDA_Complete],
	SUM(a.FTD_Complete) [FTD_Complete],
	SUM(a.LateFTD) [LateFTD],
	SUM(a.FA_Complete) [FA_Complete]

FROM 
(
SELECT 
	bdcd.NewMarketingRegion,
	bdcd.Country,
	dr.Name [Regulation],
	dr1.Name [DesignatedRegulation],
	CAST(bdcd.registered AS DATE) [Registration_Date],
	CASE WHEN bdcd.registered IS NOT NULL THEN 1 ELSE 0 END [Reg_Complete],
	dc1.Channel AS [Reg_Channel],
	dc1.SubChannel AS [Reg_SubChannel],
	CASE WHEN dc.CountryID <> dc.CountryIDByIP AND dc.VerificationLevelID <> 3 THEN 1 ELSE 0 END [PotentialBot],
    CASE WHEN bdcd.VerificationLevel1Date IS NOT NULL THEN 1 ELSE 0 END [V1_Complete],
    CASE WHEN bdcd.VerificationLevel2Date IS NOT NULL THEN 1 ELSE 0 END [V2_Complete],
    CASE WHEN bdcd.VerificationLevel3Date IS NOT NULL THEN 1 ELSE 0 END [V3_Complete],
--	CASE WHEN bdcd.FirstDepositAttempt IS NOT NULL THEN 1 ELSE 0 END [FTDA_Complete],
	CASE
      WHEN bdcd.FirstDepositAttempt IS NULL THEN (
	  CASE 
		WHEN YEAR(bdcd.FirstDepositDate) = 1900 THEN 0 -- never made FTD
		ELSE 1 END)  
      WHEN bdcd.FirstDepositAttempt IS NOT NULL THEN 1
    END [FTDA_Complete],
    CASE WHEN YEAR(bdcd.FirstDepositDate) <> 1900 THEN 1 ELSE 0 END [FTD_Complete],
	CASE WHEN YEAR(bdcd.FirstDepositDate) <> 1900 AND DATEDIFF(DAY, bdcd.registered, bdcd.FirstDepositDate) >= 30 THEN 1 ELSE 0 END [LateFTD],
	CASE WHEN bdfa.FirstActionDate IS NOT NULL THEN 1 ELSE 0 END [FA_Complete]
	

FROM 
	BI_DB_dbo.BI_DB_CIDFirstDates bdcd
	JOIN DWH_dbo.Dim_Regulation dr ON bdcd.RegulationID = dr.ID
	JOIN DWH_dbo.Dim_Regulation dr1 ON bdcd.DesignatedRegulationID = dr1.ID
	LEFT JOIN BI_DB_dbo.BI_DB_First5Actions bdfa ON bdcd.CID = bdfa.CID
	JOIN DWH_dbo.Dim_Customer dc ON bdcd.CID = dc.RealCID
	JOIN DWH_dbo.Dim_Channel dc1 ON dc.SubChannelID = dc1.SubChannelID
	
WHERE
	YEAR(CAST(bdcd.registered AS DATE)) >= 2023

) a

GROUP BY
	a.NewMarketingRegion,
	a.Country,
	a.Regulation,
	a.DesignatedRegulation,
	a.Registration_Date,
	a.Reg_Channel,
	a.Reg_SubChannel,
	a.PotentialBot