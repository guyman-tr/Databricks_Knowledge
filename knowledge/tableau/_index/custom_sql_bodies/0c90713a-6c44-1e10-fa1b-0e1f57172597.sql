SELECT eomonth(fbd.ModificationDate) AS 'Month',
fbd.IsFTD,
CASE WHEN fbd.PaymentStatusID=2 THEN 1 ELSE 0 END AS 'Approved',
'Deposit' AS 'Ind',
dpl.Name 'Club',
dc.MarketingRegionManualName AS 'Region',
dr2.Name 'Regulation',
dft1.Name 'FundingType',
sum(fbd.AmountUSD) AS 'AmountUSD',
count(*) AS 'Transactions'
FROM DWH_dbo.Fact_BillingDeposit fbd
JOIN DWH_dbo.Dim_FundingType dft1 ON fbd.FundingTypeID = dft1.FundingTypeID
JOIN DWH_dbo.Fact_SnapshotCustomer fsc1 ON fsc1.RealCID=fbd.CID
JOIN DWH_dbo.Dim_Range dr ON fsc1.DateRangeID = dr.DateRangeID AND fbd.ModificationDateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Regulation dr2 ON dr2.DWHRegulationID=fsc1.RegulationID
JOIN DWH_dbo.Dim_Country dc ON fsc1.CountryID = dc.CountryID
JOIN DWH_dbo.Dim_PlayerLevel dpl ON fsc1.PlayerLevelID = dpl.PlayerLevelID

WHERE fbd.ModificationDateID>=20230101
GROUP BY eomonth(fbd.ModificationDate) ,
fbd.IsFTD,
CASE WHEN fbd.PaymentStatusID=2 THEN 1 ELSE 0 END ,
dpl.Name ,
dc.MarketingRegionManualName ,
dr2.Name ,
dft1.Name 

UNION all

SELECT EOMONTH(fbw.ModificationDate) as'Month',
NULL 'IsFTD',
CASE WHEN ISNULL(fbw.CashoutStatusID_Funding,fbw.CashoutStatusID_Withdraw)=3 THEN 1 ELSE 0 END AS 'Approved',
'Cashout' AS 'Ind',
dpl.Name AS 'Club',
dc1.MarketingRegionManualName AS 'Region',
dr1.Name 'Regulation',
dft.Name 'FundingType',
sum(fbw.Amount_WithdrawToFunding) AS 'AmountUSD',
count(*) AS 'Transactions'
FROM DWH_dbo.Fact_BillingWithdraw fbw 
JOIN DWH_dbo.Dim_FundingType dft ON dft.FundingTypeID=fbw.FundingTypeID_Funding
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON fbw.CID=fsc.RealCID
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND fbw.ModificationDateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Country dc1 ON fsc.CountryID = dc1.CountryID
JOIN DWH_dbo.Dim_PlayerLevel dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
JOIN DWH_dbo.Dim_Regulation dr1 ON dr1.DWHRegulationID=fsc.RegulationID

WHERE  fbw.ModificationDateID>=20230101 
GROUP BY  EOMONTH(fbw.ModificationDate) ,
CASE WHEN ISNULL(fbw.CashoutStatusID_Funding,fbw.CashoutStatusID_Withdraw)=3 THEN 1 ELSE 0 END ,
dpl.Name ,
dc1.MarketingRegionManualName ,
dr1.Name ,
dft.Name