SELECT
  base.*,
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
    dr.Name AS [Regulation]
  FROM
    DWH..Dim_Date dd, DWH..Dim_Country dc, DWH..Dim_Regulation dr
  WHERE
    dd.CalendarYear >= 2022
	AND dd.CalendarYear <= YEAR(GETDATE())
	AND dd.FullDate < GETDATE()
) base
LEFT JOIN (
  SELECT
    dc1.MarketingRegionManualName AS [MarketingRegion],
    dc1.Name AS [Country],
    dr.Name AS [Regulation],
    CAST(dc.RegisteredReal AS DATE) AS [RegistrationDate],
    COUNT(DISTINCT dc.GCID) AS [RegisteredCID_Count]
  FROM
    DWH..Dim_Customer dc
    LEFT JOIN DWH..Dim_Country dc1 ON dc.CountryID = dc1.CountryID
    LEFT JOIN DWH..Dim_Regulation dr ON dc.RegulationID = dr.ID
  GROUP BY
    dc1.MarketingRegionManualName,
    dc1.Name,
    dr.Name,
    CAST(dc.RegisteredReal AS DATE)
) reg ON base.FullDate = reg.RegistrationDate
  AND base.MarketingRegion = reg.MarketingRegion
  AND base.Country = reg.Country
  AND base.Regulation = reg.Regulation
LEFT JOIN (
  SELECT
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name AS [Regulation],
    CAST(bdcd.VerificationLevel1Date AS DATE) AS [VL1_Date],
    COUNT(DISTINCT bdcd.CID) AS [V1_CompleteCount]
  FROM
    BI_DB..BI_DB_CIDFirstDates bdcd
    LEFT JOIN DWH..Dim_Regulation dr ON bdcd.RegulationID = dr.ID
  GROUP BY
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name,
    CAST(bdcd.VerificationLevel1Date AS DATE)
) vl1 ON base.FullDate = vl1.VL1_Date
  AND base.Regulation = vl1.Regulation
  AND base.MarketingRegion = vl1.NewMarketingRegion
  AND base.Country = vl1.Country
LEFT JOIN (
  SELECT
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name AS [Regulation],
    CAST(bdcd.VerificationLevel2Date AS DATE) AS [VL2_Date],
    COUNT(DISTINCT bdcd.CID) AS [V2_CompleteCount]
  FROM
    BI_DB..BI_DB_CIDFirstDates bdcd
    LEFT JOIN DWH..Dim_Regulation dr ON bdcd.RegulationID = dr.ID
  GROUP BY
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name,
    CAST(bdcd.VerificationLevel2Date AS DATE)
) vl2 ON base.FullDate = vl2.VL2_Date
  AND base.Regulation = vl2.Regulation
  AND base.MarketingRegion = vl2.NewMarketingRegion
  AND base.Country = vl2.Country
LEFT JOIN (
  SELECT
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name AS [Regulation],
    CAST(bdcd.VerificationLevel3Date AS DATE) AS [VL3_Date],
    COUNT(DISTINCT bdcd.CID) AS [V3_CompleteCount]
  FROM
    BI_DB..BI_DB_CIDFirstDates bdcd
    LEFT JOIN DWH..Dim_Regulation dr ON bdcd.RegulationID = dr.ID
  GROUP BY
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name,
    CAST(bdcd.VerificationLevel3Date AS DATE)
) vl3 ON base.FullDate = vl3.VL3_Date
  AND base.Regulation = vl3.Regulation
  AND base.MarketingRegion = vl3.NewMarketingRegion
  AND base.Country = vl3.Country
LEFT JOIN (
  SELECT
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name AS [Regulation],
    CASE
      WHEN bdcd.FirstDepositAttempt IS NULL AND bdcd.FirstDepositDate IS NOT NULL THEN bdcd.FirstDepositDate
      ELSE bdcd.FirstDepositAttempt
    END AS [FDA_Date],
    COUNT(DISTINCT bdcd.CID) AS [FirstDepAtt_Count]
  FROM
    BI_DB..BI_DB_CIDFirstDates bdcd
    LEFT JOIN DWH..Dim_Regulation dr ON bdcd.RegulationID = dr.ID
  GROUP BY
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name,
    CASE
      WHEN bdcd.FirstDepositAttempt IS NULL AND bdcd.FirstDepositDate IS NOT NULL THEN bdcd.FirstDepositDate
      ELSE bdcd.FirstDepositAttempt
    END
) fda ON base.FullDate = fda.FDA_Date
  AND base.Regulation = fda.Regulation
  AND base.MarketingRegion = fda.NewMarketingRegion
  AND base.Country = fda.Country
LEFT JOIN (
  SELECT
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name AS [Regulation],
    CAST(bdcd.FirstDepositDate AS DATE) AS [FTD_Date],
    COUNT(DISTINCT bdcd.CID) AS [FTD_Count],
    SUM(CASE WHEN DATEDIFF(DAY, bdcd.registered, bdcd.FirstDepositDate) >= 30 THEN 1 ELSE 0 END) AS [LateFTD]
  FROM
    BI_DB..BI_DB_CIDFirstDates bdcd
    LEFT JOIN DWH..Dim_Regulation dr ON bdcd.RegulationID = dr.ID
  GROUP BY
    bdcd.NewMarketingRegion,
    bdcd.Country,
    dr.Name,
    CAST(bdcd.FirstDepositDate AS DATE)
) ftd ON base.FullDate = ftd.FTD_Date
  AND base.Regulation = ftd.Regulation
  AND base.MarketingRegion = ftd.NewMarketingRegion
  AND base.Country = ftd.Country
LEFT JOIN (
  SELECT
    bdfa.NewMarketingRegion,
    bdfa.Country,
    dr.Name AS [Regulation],
    CAST(bdfa.FirstActionDate AS DATE) AS [FirstAction_Date],
    COUNT(DISTINCT bdfa.CID) AS [FirstAction_Count]
  FROM
    BI_DB..BI_DB_First5Actions bdfa
    LEFT JOIN BI_DB..BI_DB_CIDFirstDates bdcd ON bdfa.CID = bdcd.CID
    LEFT JOIN DWH..Dim_Regulation dr ON bdcd.RegulationID = dr.ID
  GROUP BY
    bdfa.NewMarketingRegion,
    bdfa.Country,
    dr.Name,
    CAST(bdfa.FirstActionDate AS DATE)
) F1A ON base.FullDate = F1A.FirstAction_Date
  AND base.MarketingRegion = F1A.NewMarketingRegion
  AND base.Country = F1A.Country
  AND base.Regulation = F1A.Regulation