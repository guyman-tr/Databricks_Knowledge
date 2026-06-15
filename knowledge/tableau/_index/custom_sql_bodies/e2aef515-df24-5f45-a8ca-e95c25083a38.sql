select 
count(distinct bd.CID) as FTDs, 
cast (bd.ModificationDate as date) as FTDDate			
from [BI_DB_dbo].BI_DB_AllDeposits bd 															
where
 bd.ModificationDate>=dateadd(day,-30,getdate())   
 and IsFTD = 1 
 and PaymentStatus in ('Approved')
group by cast (bd.ModificationDate as date)