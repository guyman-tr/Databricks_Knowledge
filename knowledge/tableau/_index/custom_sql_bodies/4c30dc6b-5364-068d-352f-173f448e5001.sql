SELECT 
distinct 
dc.RealCID, dc.FirstDepositDate, dc.FirstDepositAmount,
dc1.Name as KYCCountry, dc2.Name As RegCountry
from DWH_dbo.Dim_Customer dc
LEFT JOIN BI_DB_dbo.BI_DB_CIDFirstDates cf on cf.CID=dc.RealCID
join DWH_dbo.Dim_Country dc1 on dc1.CountryID=dc.CountryID
join DWH_dbo.Dim_Country dc2 on dc2.CountryID=dc.CountryIDByIP
join DWH_dbo.Dim_Position DP ON DP.CID=dc.RealCID and DP.CloseDateID=0
where
(
dc.CountryIDByIP=161 -- Peru
or dc.CountryID=161 --Peru
)
and dc.IsDepositor=1
and dc.FirstDepositAmount>=1000
and datediff(day,dc.FirstDepositDate,getdate())>=30
and DP.Leverage>=30