SELECT 
dc.Name 'Country',
dc2.Abbreviation'Currency',
dft.Name 'MOP',
fbd.ModificationDate,
EOMONTH(fbd.ModificationDate) AS 'EOM',
'Deposit' AS 'Ind',
IsFTD,
dpl.Name 'Club',
dr1.Name 'Regulation',
dc.MarketingRegionManualName,
sum(fbd.AmountUSD) AS 'AmountUSD'

FROM DWH_dbo.Fact_BillingDeposit fbd
JOIN DWH_dbo.Dim_FundingType dft ON fbd.FundingTypeID = dft.FundingTypeID
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON fbd.CID=fsc.RealCID
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND fbd.ModificationDateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Country dc ON fsc.CountryID = dc.CountryID
JOIN DWH_dbo.Dim_Currency dc2 ON fbd.CurrencyID = dc2.CurrencyID
JOIN DWH_dbo.Dim_PlayerLevel dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
JOIN DWH_dbo.Dim_Regulation dr1 ON dr1.DWHRegulationID=fsc.RegulationID
WHERE fbd.PaymentStatusID=2 
AND fbd.ModificationDateID>=20230801
AND fsc.IsValidCustomer=1

GROUP BY dc.Name ,
dc2.Abbreviation,
dft.Name,
fbd.ModificationDate,
EOMONTH(fbd.ModificationDate),
IsFTD,
dpl.Name ,
dr1.Name,
dc.MarketingRegionManualName

UNION ALL 

SELECT dc1.Name  'Country',
dc.Abbreviation 'Currency',
dft.Name AS 'MOP',
fbw.ModificationDate,
eomonth(fbw.ModificationDate) AS 'EOM',
'CO' AS 'Ind',
null as 'IsFTD',
dpl.Name 'Club',
dr1.Name 'Regulation',
dc1.MarketingRegionManualName,
sum(fbw.Amount_WithdrawToFunding) AS 'AmountUSD'
FROM DWH_dbo.Fact_BillingWithdraw fbw 
JOIN DWH_dbo.Dim_FundingType dft ON dft.FundingTypeID=fbw.FundingTypeID_Funding
JOIN DWH_dbo.Dim_Currency dc ON fbw.ProcessCurrencyID = dc.CurrencyID
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON fbw.CID=fsc.RealCID
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND fbw.ModificationDateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Country dc1 ON fsc.CountryID = dc1.CountryID
JOIN DWH_dbo.Dim_PlayerLevel dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
JOIN DWH_dbo.Dim_Regulation dr1 ON dr1.DWHRegulationID=fsc.RegulationID
WHERE ISNULL(fbw.CashoutStatusID_Funding,fbw.CashoutStatusID_Withdraw)=3 AND fbw.ModificationDateID>=20230801
AND fsc.IsValidCustomer=1
GROUP BY  dc1.Name,
dc.Abbreviation ,
dft.Name,
fbw.ModificationDate,
eomonth(fbw.ModificationDate),
dpl.Name ,
dr1.Name,
dc1.MarketingRegionManualName