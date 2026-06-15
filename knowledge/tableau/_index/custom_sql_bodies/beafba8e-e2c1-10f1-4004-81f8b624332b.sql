SELECT v.CID,
v.Credit,
v.DateID,
fsc.RegulationID,
v.LiabilitiesStockReal,
v.LiabilitiesCryptoReal,
v.TotalCash,
v.TotalPositionsAmount,
v.PositionPnL,
v.InProcessCashouts,
v.ActualNWA,
v.TotalStockOrders,
v.Liabilities,
fsc.PlayerStatusID 'PlayerStatus'
FROM DWH..V_Liabilities v 
INNER JOIN DWH..Fact_SnapshotCustomer fsc ON fsc.RealCID=v.CID AND fsc.IsCreditReportValidCB=1 AND fsc.RegulationID IN (4,10)
INNER JOIN DWH..Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND v.DateID BETWEEN dr.FromDateID AND dr.ToDateID
--INNER JOIN DWH..Dim_PlayerStatus dps ON fsc.PlayerStatusID = dps.PlayerStatusID
--INNER JOIN DWH..Dim_Regulation dr1 ON fsc.RegulationID=dr1.DWHRegulationID

WHERE v.Credit<0 
AND v.DateID=CAST(CONVERT(CHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT)