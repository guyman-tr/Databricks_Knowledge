SELECT
DISTINCT (fbw.WithdrawID) AS WithdrawID,
dc.RealCID as CID,
SUM(fbw.Amount_WithdrawToFunding) AS Amount$,
dft.Name AS MOP,
dr.Name as Regulation,
CAST(fbw.ModificationDate AS DATE) AS ProcessedDate,
country.Name as Country, 
dpl.Name as [PlayerLevel],
fbw.FlowID,
fbw.WithdrawTypeID,
case when fbw.WithdrawTypeID=0 THEN 'Default' 
when fbw.WithdrawTypeID=1 then 'Transfer' 
when fbw.WithdrawTypeID=2 then 'ApprovedForClosure' else 'NULL' END AS WithdrawType,
case when fbw.FlowID=1 THEN 'Open Trade Execution' 
when fbw.FlowID=2 then 'Close Trade Execution' 
when fbw.FlowID=3 then 'Internal Transfer' else 'NULL' END AS Flow


FROM DWH_dbo.Fact_BillingWithdraw fbw
join DWH_dbo.Dim_Customer dc on dc.RealCID=fbw.CID
left join DWH_dbo.Dim_PlayerLevel dpl on dpl.PlayerLevelID=dc.PlayerLevelID
JOIN DWH_dbo.Dim_Regulation dr on dr.ID=dc.RegulationID
JOIN DWH_dbo.Dim_FundingType dft ON dft.FundingTypeID=fbw.FundingTypeID_Funding
JOIN DWH_dbo.Dim_Country country on country.CountryID=dc.CountryID
WHERE 
fbw.ModificationDate>= DATEADD(MONTH, -12, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0))	
AND fbw.CashoutStatusID_Funding=3
and dc.IsValidCustomer=1
GROUP BY fbw.WithdrawID, dc.RealCID, dft.Name, CAST(fbw.ModificationDate AS DATE),
dr.Name, country.Name,dpl.Name,fbw.FlowID,fbw.WithdrawTypeID
,case when fbw.WithdrawTypeID=0 THEN 'Default' 
when fbw.WithdrawTypeID=1 then 'Transfer' 
when fbw.WithdrawTypeID=2 then 'ApprovedForClosure' else 'NULL' END,
case when fbw.FlowID=1 THEN 'Open Trade Execution' 
when fbw.FlowID=2 then 'Close Trade Execution' 
when fbw.FlowID=3 then 'Internal Transfer' else 'NULL' END