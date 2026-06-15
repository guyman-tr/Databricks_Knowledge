select m.ManagerID
       ,Sum(l.ActualNWA + l.Liabilities) as Equity
from DWH.dbo.Dim_Customer d
join DWH.dbo.Dim_Manager m
on m.ManagerID = d.AccountManagerID
join DWH.dbo.V_Liabilities l
on l.CID = d.RealCID 
where l.DateID =CAST(CONVERT(VARCHAR(8),Dateadd(day,-1,getdate()), 112) AS INT)
group by m.ManagerID