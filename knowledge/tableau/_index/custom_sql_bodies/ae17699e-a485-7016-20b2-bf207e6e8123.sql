select m.ManagerID
       ,Sum(l.ActualNWA + l.Liabilities) as Equity
from DWH_dbo.Dim_Customer d
join DWH_dbo.Dim_Manager m
on m.ManagerID = d.AccountManagerID
join DWH_dbo.V_Liabilities l
on l.CID = d.RealCID 
where l.DateID =CAST(CONVERT(VARCHAR(8),Dateadd(day,-1,getdate()), 112) AS INT)
group by  m.ManagerID