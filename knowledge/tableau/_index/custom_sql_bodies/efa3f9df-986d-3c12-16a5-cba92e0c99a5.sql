SELECT
      EOMONTH(dc.RegisteredReal) AS Reg_Date
    , dc2.MarketingRegionManualName
    , dc.RegulationID
    , dc.PlayerLevelID
	 ,dc2.Name AS Country
	 ,reg.Name AS Regulation
    , COUNT(CASE
        WHEN dc.RegisteredReal >= DATEADD(DAY, 1, EOMONTH(GETDATE(), -6))
         AND dc.RegisteredReal <  DATEADD(DAY, 1, EOMONTH(GETDATE(), -1))
        THEN dc.RealCID
      END) AS Registered
    , COUNT(CASE
        WHEN dc.FirstDepositDate >= DATEADD(DAY, 1, EOMONTH(GETDATE(), -6))
         AND dc.FirstDepositDate <  DATEADD(DAY, 1, EOMONTH(GETDATE(), -1))
        THEN dc.RealCID
      END) AS ConvertedRegistrationFTD
FROM DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.Dim_Country dc2  ON dc.CountryID = dc2.CountryID
INNER JOIN DWH_dbo.Dim_Regulation reg ON dc.RegulationID = reg.DWHRegulationID   
WHERE dc.RegisteredReal >= DATEADD(DAY, 1, EOMONTH(GETDATE(), -6))
  AND dc.RegisteredReal <  DATEADD(DAY, 1, EOMONTH(GETDATE(), -1))
  AND dc.IsCreditReportValidCB = 1
  AND dc.IsValidCustomer = 1
  AND dc.PlayerLevelID <> 4 -- Internal
GROUP BY
      EOMONTH(dc.RegisteredReal)
    , dc2.MarketingRegionManualName
    , dc.RegulationID
    , dc.PlayerLevelID
	 ,dc2.Name 
	 ,reg.Name 
HAVING
    COUNT(CASE
        WHEN dc.RegisteredReal >= DATEADD(DAY, 1, EOMONTH(GETDATE(), -6))
         AND dc.RegisteredReal <  DATEADD(DAY, 1, EOMONTH(GETDATE(), -1))
        THEN dc.RealCID
    END) > 0
 OR
    COUNT(CASE
        WHEN dc.FirstDepositDate >= DATEADD(DAY, 1, EOMONTH(GETDATE(), -6))
         AND dc.FirstDepositDate <  DATEADD(DAY, 1, EOMONTH(GETDATE(), -1))
        THEN dc.RealCID
    END) > 0