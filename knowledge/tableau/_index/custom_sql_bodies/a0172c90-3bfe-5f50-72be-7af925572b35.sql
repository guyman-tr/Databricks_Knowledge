SELECT  <[Parameters].[Parameter 1]> AS FromDate
	, <[Parameters].[Parameter 2]> AS ToDate
--, dpl.Name AS PlayerLevel
, dps.Name AS PlayerStatus
, dr1.Name AS Regulation
, dmc.Name AS Mifid
, dc1.Name AS Country
, COUNT(fca.RealCID) AS CountDeposit
, SUM(fca.Amount) AS SumDeposit
, count (DISTINCT fca.RealCID) AS UUCountDepositors
FROM DWH_dbo.Fact_CustomerAction fca WITH (NOLOCK)
JOIN DWH_dbo.Dim_Customer dc WITH (NOLOCK)
ON fca.RealCID = dc.RealCID AND dc.RegisteredReal BETWEEN <[Parameters].[Parameter 1]> AND <[Parameters].[Parameter 2]>
JOIN DWH_dbo.Fact_SnapshotCustomer fsc WITH (NOLOCK)
ON fca.RealCID = fsc.RealCID
JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK)
ON fsc.DateRangeID = dr.DateRangeID AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Regulation dr1 WITH (NOLOCK)
ON fsc.RegulationID = dr1.DWHRegulationID
--JOIN DWH_dbo.Dim_PlayerLevel dpl
--ON dc.PlayerLevelID = dpl.PlayerLevelID
JOIN DWH_dbo.Dim_PlayerStatus dps WITH (NOLOCK)
ON dc.PlayerStatusID = dps.PlayerStatusID
JOIN DWH_dbo.Dim_MifidCategorization dmc WITH (NOLOCK)
ON dc.MifidCategorizationID = dmc.MifidCategorizationID
JOIN DWH_dbo.Dim_Country dc1 WITH (NOLOCK)
ON dc.CountryID = dc1.CountryID
WHERE fca.ActionTypeID = 7
AND fca.DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
AND fsc.IsCreditReportValidCB = 1
GROUP BY 
  dps.Name 
, dr1.Name 
, dmc.Name 
, dc1.Name