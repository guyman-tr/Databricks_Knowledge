SELECT dc.Name 'Country',
dr1.Name 'Regulation',
dps.Name 'Player Status',
dmc.Name 'MifidCategorization',
count(DISTINCT fbw.WithdrawID) AS 'Total_Cashout',
count(DISTINCT CASE WHEN fbw.CashoutStatusID_Withdraw=4 THEN fbw.WithdrawID ELSE NULL END) AS 'Cancled_Cashouts'
FROM DWH_dbo.Fact_BillingWithdraw fbw
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON fbw.CID=fsc.RealCID
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND fbw.ModificationDateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Regulation dr1 ON dr1.DWHRegulationID=fsc.RegulationID
JOIN DWH_dbo.Dim_Country dc ON fsc.CountryID = dc.CountryID
JOIN DWH_dbo.Dim_MifidCategorization dmc ON fsc.MifidCategorizationID = dmc.MifidCategorizationID
JOIN DWH_dbo.Dim_PlayerStatus dps ON fsc.PlayerStatusID = dps.PlayerStatusID
WHERE fbw.ModificationDateID>=CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
and fbw.ModificationDateID<=CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
GROUP BY dc.Name ,
dr1.Name,
dps.Name ,
dmc.Name