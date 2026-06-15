select 
a.HedgeServerID,
a.InstrumentID ,
 sum (DailyPnL) DailyPnLPrevious5Days,
Avg( ISNULL(FullCommissionPrevious5Days,0)) FullCommissionPrevious5Days
from BI_DB..BI_DB_PositionPnL a
full join 
(select HedgeServerID,
        InstrumentID,
        sum (RealizedCommission) FullCommissionPrevious5Days
from BI_DB..BI_DB_DailyZero_TreeSize_NEW  
where Date between dateadd(day,-5,cast(getdate() as Date))
and dateadd(day,-1,cast(getdate() as Date))
AND HedgeServerID IN (4,5,24)
group by HedgeServerID,InstrumentID
)c
on a.HedgeServerID=c.HedgeServerID and a.InstrumentID=c.InstrumentID
join DWH..Dim_Customer  b
on a.CID=b.RealCID

where DateID between CAST(convert(VARCHAR(8),GETDATE()-5,112)AS INT) and 
CAST(convert(VARCHAR(8),GETDATE()-1,112)AS INT)
and b.IsValidCustomer=1
AND a.HedgeServerID IN (4,5,24)
group by a.HedgeServerID,a.InstrumentID