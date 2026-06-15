SELECT
  base.*,
  reg.PotentialBot,
  ISNULL(reg.RegisteredCID_Count,0) RegisteredCID_Count,
  ISNULL(vl1.V1_CompleteCount,0) V1_CompleteCount,
  ISNULL(vl2.V2_CompleteCount,0) V2_CompleteCount,
  ISNULL(vl3.V3_CompleteCount,0) V3_CompleteCount,
  ISNULL(fda.FirstDepAtt_Count,0) FirstDepAtt_Count,
  ISNULL(ftd.FTD_Count,0) FTD_Count,
  ISNULL(ftd.LateFTD,0) LateFTD,
  ISNULL(F1A.FirstAction_Count,0) FirstAction_Count



FROM (
  SELECT
    dd.FullDate,
    dd.DateKey,
    dc.MarketingRegionManualName AS [MarketingRegion],
    dc.Name AS [Country],
    dr.Name AS [Regulation],
	dr1.Name AS [DesignatedRegulation]
--	,dc1.Channel AS [Channel]
--	,dc1.SubChannel AS [SubChannel]
  FROM
    DWH_dbo.Dim_Date dd, 
	DWH_dbo.Dim_Country dc, 
	DWH_dbo.Dim_Regulation dr,
	DWH_dbo.Dim_Regulation dr1
--	,DWH_dbo.Dim_Channel dc1
  WHERE
    dd.CalendarYear >= 2024
	AND dd.CalendarYear <= YEAR(GETDATE())
	AND dd.FullDate < GETDATE()
) base



LEFT JOIN (
  SELECT
    dc1.MarketingRegionManualName AS [MarketingRegion],
    dc1.Name AS [Country],
    dr.Name AS [Regulation],
	dr1.Name AS [DesignatedRegulation],
	CASE WHEN dc.CountryID <> dc.CountryIDByIP AND dc.VerificationLevelID <> 3 THEN 1 ELSE 0 END [PotentialBot],
--	dc2.Channel AS [Channel],
--	dc2.SubChannel AS [SubChannel],
    CAST(dc.RegisteredReal AS DATE) AS [RegistrationDate],
    COUNT(DISTINCT dc.GCID) AS [RegisteredCID_Count]
  FROM
    DWH_dbo.Dim_Customer dc
    LEFT JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID = dc1.CountryID
    LEFT JOIN DWH_dbo.Dim_Regulation dr ON dc.RegulationID = dr.ID
	LEFT JOIN DWH_dbo.Dim_Regulation dr1 ON dc.DesignatedRegulationID = dr1.ID
--	LEFT JOIN DWH_dbo.Dim_Channel dc2 ON dc.SubChannelID = dc2.SubChannelID
  GROUP BY
    dc1.MarketingRegionManualName,
    dc1.Name,
    dr.Name,
	dr1.Name,
	CASE WHEN dc.CountryID <> dc.CountryIDByIP AND dc.VerificationLevelID <> 3 THEN 1 ELSE 0 END,
--	dc2.Channel,
--	dc2.SubChannel,
    CAST(dc.RegisteredReal AS DATE)
) reg ON base.FullDate = reg.RegistrationDate
  AND base.MarketingRegion = reg.MarketingRegion
  AND base.Country = reg.Country
  AND base.Regulation = reg.Regulation
  AND base.DesignatedRegulation = reg.DesignatedRegulation
--  AND base.Channel = reg.Channel
--  AND base.SubChannel = reg.SubChannel


LEFT JOIN (
  SELECT
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name AS [Regulation],
	dr1.Name AS [DesignatedRegulation],
	CASE WHEN dc.CountryID <> dc.CountryIDByIP AND dc.VerificationLevelID <> 3 THEN 1 ELSE 0 END [PotentialBot],	
--	bdcd.Channel AS [Channel],
--	bdcd.SubChannel AS [SubChannel],
    CAST(bdcd.VerificationLevel1Date AS DATE) AS [VL1_Date],
    COUNT(DISTINCT bdcd.CID) AS [V1_CompleteCount]
  FROM
    BI_DB_dbo.BI_DB_CIDFirstDates bdcd
	JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID = bdcd.CID
    LEFT JOIN DWH_dbo.Dim_Regulation dr ON bdcd.RegulationID = dr.ID
	LEFT JOIN DWH_dbo.Dim_Regulation dr1 ON bdcd.DesignatedRegulationID = dr1.ID
  GROUP BY
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name,
	dr1.Name,
	CASE WHEN dc.CountryID <> dc.CountryIDByIP AND dc.VerificationLevelID <> 3 THEN 1 ELSE 0 END,
--	bdcd.Channel,
--	bdcd.SubChannel,
    CAST(bdcd.VerificationLevel1Date AS DATE)
) vl1 ON base.FullDate = vl1.VL1_Date
  AND base.Regulation = vl1.Regulation
  AND base.DesignatedRegulation = vl1.DesignatedRegulation
  AND base.MarketingRegion = vl1.NewMarketingRegion
  AND base.Country = vl1.Country
  AND reg.PotentialBot = vl1.PotentialBot
--  AND base.Channel = vl1.Channel
--  AND base.SubChannel = vl1.SubChannel


LEFT JOIN (
  SELECT
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name AS [Regulation],
	dr1.Name AS [DesignatedRegulation],
	CASE WHEN dc.CountryID <> dc.CountryIDByIP AND dc.VerificationLevelID <> 3 THEN 1 ELSE 0 END [PotentialBot],
--	bdcd.Channel AS [Channel],
--	bdcd.SubChannel AS [SubChannel],
    CAST(bdcd.VerificationLevel2Date AS DATE) AS [VL2_Date],
    COUNT(DISTINCT bdcd.CID) AS [V2_CompleteCount]
  FROM
    BI_DB_dbo.BI_DB_CIDFirstDates bdcd
	JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID = bdcd.CID
    LEFT JOIN DWH_dbo.Dim_Regulation dr ON bdcd.RegulationID = dr.ID
	LEFT JOIN DWH_dbo.Dim_Regulation dr1 ON bdcd.DesignatedRegulationID = dr1.ID
  GROUP BY
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name,
	dr1.Name,
	CASE WHEN dc.CountryID <> dc.CountryIDByIP AND dc.VerificationLevelID <> 3 THEN 1 ELSE 0 END,
--	bdcd.Channel,
--	bdcd.SubChannel,
    CAST(bdcd.VerificationLevel2Date AS DATE)
) vl2 ON base.FullDate = vl2.VL2_Date
  AND base.Regulation = vl2.Regulation
  AND base.DesignatedRegulation = vl2.DesignatedRegulation
  AND base.MarketingRegion = vl2.NewMarketingRegion
  AND base.Country = vl2.Country
  AND reg.PotentialBot = vl2.PotentialBot
--  AND base.Channel = vl2.Channel
--  AND base.SubChannel = vl2.SubChannel


LEFT JOIN (
  SELECT
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name AS [Regulation],
	dr1.Name AS [DesignatedRegulation],
	CASE WHEN dc.CountryID <> dc.CountryIDByIP AND dc.VerificationLevelID <> 3 THEN 1 ELSE 0 END [PotentialBot],
--	bdcd.Channel AS [Channel],
--	bdcd.SubChannel AS [SubChannel],
    CAST(bdcd.VerificationLevel3Date AS DATE) AS [VL3_Date],
    COUNT(DISTINCT bdcd.CID) AS [V3_CompleteCount]
  FROM
    BI_DB_dbo.BI_DB_CIDFirstDates bdcd
	JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID = bdcd.CID
    LEFT JOIN DWH_dbo.Dim_Regulation dr ON bdcd.RegulationID = dr.ID
	LEFT JOIN DWH_dbo.Dim_Regulation dr1 ON bdcd.DesignatedRegulationID = dr1.ID
  GROUP BY
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name,
	dr1.Name,
	CASE WHEN dc.CountryID <> dc.CountryIDByIP AND dc.VerificationLevelID <> 3 THEN 1 ELSE 0 END,
--	bdcd.Channel,
--	bdcd.SubChannel,
    CAST(bdcd.VerificationLevel3Date AS DATE)
) vl3 ON base.FullDate = vl3.VL3_Date
  AND base.Regulation = vl3.Regulation
  AND base.DesignatedRegulation = vl3.DesignatedRegulation
  AND base.MarketingRegion = vl3.NewMarketingRegion
  AND base.Country = vl3.Country
  AND reg.PotentialBot = vl3.PotentialBot
--  AND base.Channel = vl3.Channel
--  AND base.SubChannel = vl3.SubChannel




LEFT JOIN (
  SELECT
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name AS [Regulation],
	dr1.Name AS [DesignatedRegulation],
	CASE WHEN dc.CountryID <> dc.CountryIDByIP AND dc.VerificationLevelID <> 3 THEN 1 ELSE 0 END [PotentialBot],
--	bdcd.Channel AS [Channel],
--	bdcd.SubChannel AS [SubChannel],
--    CASE
--      WHEN bdcd.FirstDepositAttempt IS NOT NULL AND bdcd.FirstDepositDate IS NOT NULL THEN bdcd.FirstDepositDate
--      WHEN bdcd.FirstDepositAttempt IS NOT NULL AND bdcd.FirstDepositDate IS NULL THEN bdcd.FirstDepositAttempt
 --   END AS [FDA_Date],

    CASE
      WHEN bdcd.FirstDepositAttempt IS NULL THEN (
	  CASE 
		WHEN YEAR(bdcd.FirstDepositDate) < 2000 THEN NULL
		ELSE CAST(bdcd.FirstDepositDate AS DATE) END)  
      WHEN bdcd.FirstDepositAttempt IS NOT NULL THEN CAST(bdcd.FirstDepositAttempt AS DATE)
    END AS [FDA_Date],

    COUNT(DISTINCT bdcd.CID) AS [FirstDepAtt_Count]
  FROM
    BI_DB_dbo.BI_DB_CIDFirstDates bdcd
	JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID = bdcd.CID
    LEFT JOIN DWH_dbo.Dim_Regulation dr ON bdcd.RegulationID = dr.ID
	LEFT JOIN DWH_dbo.Dim_Regulation dr1 ON bdcd.DesignatedRegulationID = dr1.ID
  GROUP BY
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name,
	dr1.Name,
	CASE WHEN dc.CountryID <> dc.CountryIDByIP AND dc.VerificationLevelID <> 3 THEN 1 ELSE 0 END,
--	bdcd.Channel,
--	bdcd.SubChannel,
--    CASE
--      WHEN bdcd.FirstDepositAttempt IS NOT NULL AND bdcd.FirstDepositDate IS NOT NULL THEN bdcd.FirstDepositDate
--      WHEN bdcd.FirstDepositAttempt IS NOT NULL AND bdcd.FirstDepositDate IS NULL THEN bdcd.FirstDepositAttempt
--    END


    CASE
      WHEN bdcd.FirstDepositAttempt IS NULL THEN (
	  CASE 
		WHEN YEAR(bdcd.FirstDepositDate) < 2000 THEN NULL
		ELSE CAST(bdcd.FirstDepositDate AS DATE) END)  
      WHEN bdcd.FirstDepositAttempt IS NOT NULL THEN CAST(bdcd.FirstDepositAttempt AS DATE)
    END

) fda ON base.FullDate = fda.FDA_Date
  AND base.Regulation = fda.Regulation
  AND base.DesignatedRegulation = fda.DesignatedRegulation
  AND base.MarketingRegion = fda.NewMarketingRegion
  AND base.Country = fda.Country
  AND reg.PotentialBot = fda.PotentialBot
--  AND base.Channel = fda.Channel
--  AND base.SubChannel = fda.SubChannel



LEFT JOIN (
  SELECT
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name AS [Regulation],
	dr1.Name AS [DesignatedRegulation],
	CASE WHEN dc.CountryID <> dc.CountryIDByIP AND dc.VerificationLevelID <> 3 THEN 1 ELSE 0 END [PotentialBot],
--	bdcd.Channel AS [Channel],
--	bdcd.SubChannel AS [SubChannel],
    CAST(bdcd.FirstDepositDate AS DATE) AS [FTD_Date],
    COUNT(DISTINCT bdcd.CID) AS [FTD_Count],
    SUM(CASE WHEN DATEDIFF(DAY, bdcd.registered, bdcd.FirstDepositDate) >= 30 THEN 1 ELSE 0 END) AS [LateFTD]
  FROM
    BI_DB_dbo.BI_DB_CIDFirstDates bdcd
	JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID = bdcd.CID
    LEFT JOIN DWH_dbo.Dim_Regulation dr ON bdcd.RegulationID = dr.ID
	LEFT JOIN DWH_dbo.Dim_Regulation dr1 ON bdcd.DesignatedRegulationID = dr1.ID
  GROUP BY
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name,
	dr1.Name,
	CASE WHEN dc.CountryID <> dc.CountryIDByIP AND dc.VerificationLevelID <> 3 THEN 1 ELSE 0 END,
--	bdcd.Channel,
--	bdcd.SubChannel,
    CAST(bdcd.FirstDepositDate AS DATE)
) ftd ON base.FullDate = ftd.FTD_Date
  AND base.Regulation = ftd.Regulation
  AND base.DesignatedRegulation = ftd.DesignatedRegulation
  AND base.MarketingRegion = ftd.NewMarketingRegion
  AND base.Country = ftd.Country
  AND reg.PotentialBot = ftd.PotentialBot
--  AND base.Channel = ftd.Channel
--  AND base.SubChannel = ftd.SubChannel



LEFT JOIN (
  SELECT
    bdfa.NewMarketingRegion,
    bdfa.Country,
    dr.Name AS [Regulation],
	dr1.Name AS [DesignatedRegulation],
	CASE WHEN dc.CountryID <> dc.CountryIDByIP AND dc.VerificationLevelID <> 3 THEN 1 ELSE 0 END [PotentialBot],
--	bdcd.Channel AS [Channel],
--	bdcd.SubChannel AS [SubChannel],
    CAST(bdfa.FirstActionDate AS DATE) AS [FirstAction_Date],
    COUNT(DISTINCT bdfa.CID) AS [FirstAction_Count]
  FROM
    BI_DB_dbo.BI_DB_First5Actions bdfa
	JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID = bdfa.CID
    LEFT JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdcd ON bdfa.CID = bdcd.CID
    LEFT JOIN DWH_dbo.Dim_Regulation dr ON bdcd.RegulationID = dr.ID
	LEFT JOIN DWH_dbo.Dim_Regulation dr1 ON bdcd.DesignatedRegulationID = dr1.ID
  GROUP BY
    bdfa.NewMarketingRegion,
    bdfa.Country,
    dr.Name,
	dr1.Name,
	CASE WHEN dc.CountryID <> dc.CountryIDByIP AND dc.VerificationLevelID <> 3 THEN 1 ELSE 0 END,
--	bdcd.Channel,
--	bdcd.SubChannel,
    CAST(bdfa.FirstActionDate AS DATE)
) F1A ON base.FullDate = F1A.FirstAction_Date
  AND base.MarketingRegion = F1A.NewMarketingRegion
  AND base.Country = F1A.Country
  AND base.Regulation = F1A.Regulation
  AND base.DesignatedRegulation = F1A.DesignatedRegulation
  AND reg.PotentialBot = F1A.PotentialBot
--  AND base.Channel = F1A.Channel
--  AND base.SubChannel = F1A.SubChannel