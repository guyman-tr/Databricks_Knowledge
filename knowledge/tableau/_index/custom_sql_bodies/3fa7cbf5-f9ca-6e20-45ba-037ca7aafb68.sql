select 
	dp.Country,
	sum(dp.Revenue_Total) as Commissions,
	sum(Case when dc.RegisteredReal>='20260101' then dp.Revenue_Total else 0 end) as Commisions2025newClients,
	sum(Case when dc.FirstDepositDate>='20260101' then dp.Revenue_Total else 0 end) as Commisions2025FTDs
from 
	BI_DB_dbo.BI_DB_CID_DailyPanel_FullData dp
LEFT JOIN 
	DWH_dbo.Dim_Customer dc on dc.RealCID=dp.CID
where 
	dp.DateID>='20260101'
	and dp.DateID < '20260401'
group by 
	dp.Country