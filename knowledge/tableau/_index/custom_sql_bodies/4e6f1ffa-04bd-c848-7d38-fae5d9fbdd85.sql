SELECT
DISTINCT fbw.WithdrawID AS WithdrawID,
dc.RealCID as CID,
SUM(CASE WHEN fbw.Amount_WithdrawToFunding IS NOT NULL THEN fbw.Amount_WithdrawToFunding ELSE fbw.Amount_Withdraw end) AS Amount$,
case when dft.Name is not null then dft.Name else dft1.Name end AS MOP,
dr.Name as Regulation,
CAST(fbw.ModificationDate AS DATE) AS ProcessedDate,
CAST(fbw.RequestDate AS DATE) AS RequestDate,
country.Name as Country, 
dpl.Name as [PlayerLevel],
fbw.FlowID,
fbw.WithdrawTypeID,
case when fbw.WithdrawTypeID=0 THEN 'Default' 
when fbw.WithdrawTypeID=1 then 'Transfer' 
when fbw.WithdrawTypeID=2 then 'ApprovedForClosure' else 'NULL' END AS WithdrawType,
case when fbw.FlowID=1 THEN 'Open Trade Execution' 
when fbw.FlowID=2 then 'Close Trade Execution' 
when fbw.FlowID=3 then 'Internal Transfer' else 'NULL' END AS Flow,
s.Name AS CashoutStatus_WithdrawID,
s1.Name as CashoutStatus_FundingID
FROM DWH_dbo.Fact_BillingWithdraw fbw
join DWH_dbo.Dim_Customer dc on dc.RealCID=fbw.CID
left join DWH_dbo.Dim_PlayerLevel dpl on dpl.PlayerLevelID=dc.PlayerLevelID
LEFT JOIN DWH_dbo.Dim_Regulation dr on dr.ID=dc.RegulationID
LEFT JOIN DWH_dbo.Dim_FundingType dft ON dft.FundingTypeID=fbw.FundingTypeID_Funding
LEFT JOIN DWH_dbo.Dim_FundingType dft1 ON dft1.FundingTypeID=fbw.FundingTypeID_Withdraw
JOIN DWH_dbo.Dim_Country country on country.CountryID=dc.CountryID
left JOIN DWH_dbo.Dim_CashoutStatus s on s.CashoutStatusID=fbw.CashoutStatusID_Withdraw
left JOIN DWH_dbo.Dim_CashoutStatus s1 on s1.CashoutStatusID=fbw.CashoutStatusID_Funding
WHERE 
fbw.ModificationDate>= DATEADD(MONTH, -12, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0))	
and dc.IsValidCustomer=1
and fbw.WithdrawTypeID=1 
GROUP BY fbw.WithdrawID, 
dc.RealCID, 
dft.Name,
case when dft.Name is not null then dft.Name else dft1.Name end ,
CAST(fbw.ModificationDate AS DATE),
dr.Name, country.Name,dpl.Name,fbw.FlowID,fbw.WithdrawTypeID
,case when fbw.WithdrawTypeID=0 THEN 'Default' 
when fbw.WithdrawTypeID=1 then 'Transfer' 
when fbw.WithdrawTypeID=2 then 'ApprovedForClosure' else 'NULL' END,
case when fbw.FlowID=1 THEN 'Open Trade Execution' 
when fbw.FlowID=2 then 'Close Trade Execution' 
when fbw.FlowID=3 then 'Internal Transfer' else 'NULL' END
,s.Name ,
CAST(fbw.RequestDate AS DATE),s1.Name