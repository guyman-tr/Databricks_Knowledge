SELECT 
DISTINCT w.WithdrawID, w.CID, w.Amount, w.RequestDate, cs.Name as CashoutStatus

,dc1.Name as Country
FROM BI_DB_dbo.External_etoro_Billing_Withdraw w
join DWH_dbo.Dim_CashoutStatus cs on cs.CashoutStatusID=w.CashoutStatusID
join DWH_dbo.Dim_Customer dc on dc.RealCID=w.CID
JOIN DWH_dbo.Dim_Country dc1 on dc1.CountryID=dc.CountryID
WHERE w.Amount>100000 AND w.FundingTypeID=33 --eToroMoney 
AND w.CashoutStatusID NOT IN (3,4)