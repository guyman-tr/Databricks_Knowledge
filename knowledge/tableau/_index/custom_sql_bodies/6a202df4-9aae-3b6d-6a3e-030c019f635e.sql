select 
count(distinct bd.CID) as FTDs, 
cast (bd.ModificationDate as date) as FTDDate			
from BI_DB_dbo.BI_DB_AllDeposits bd 														
JOIN DWH_dbo.Dim_Customer  CC ON bd.CID=CC.RealCID												
where
 bd.ModificationDate>=dateadd(day,-30,getdate())   
 and IsFTD = 1 
 and PaymentStatus IN ('Approved')
 and CC.IsValidCustomer=1
group by cast (bd.ModificationDate as date)