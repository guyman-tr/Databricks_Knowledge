select 
	bd.[ModificationDate] as ActionTime
,	bd.DepositID
,	bd.Amount AS 'Amount In Orig Curr'
,	bd.Amount* bd.ExchangeRate AS 'Amount in $'
,	CURR.Abbreviation as Currency
,	dr.Name as Regulation
,	bd.CID
,	bd.ProcessorValueDate as DepositValueDate
,	dm.FirstName + ' ' + dm.LastName as ProccessedBy
from  [BI_DB_dbo].[External_etoro_Billing_Deposit] bd 
LEFT JOIN DWH_dbo.Dim_Currency CURR ON CURR.CurrencyID=bd.CurrencyID 
left join DWH_dbo.Dim_Customer cc  on cc.RealCID=bd.CID
join DWH_dbo.Dim_Regulation dr  on dr.ID=cc.RegulationID
left join  [BI_DB_dbo].[External_etoro_Billing_Funding] Funding   on bd.FundingID=Funding.FundingID
left join DWH_dbo.Dim_Manager dm on dm.ManagerID=bd.ManagerID
where convert(date,bd.[ModificationDate]) >= convert(date, getdate()-180)
and Funding.FundingTypeID=2 and bd.PaymentStatusID=2