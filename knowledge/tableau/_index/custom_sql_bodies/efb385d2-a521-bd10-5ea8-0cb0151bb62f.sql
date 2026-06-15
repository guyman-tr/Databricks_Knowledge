select * from (
select bd.CID
      ,bm.FirstName+' '+bm.LastName as Manager
      ,bm.ManagerID
      ,bd.Amount
	  ,IsFTD
	  ,ROW_NUMBER() over (partition by bd.CID order by sf.CreatedDate_SF) as rn
from [AZR-W-REAL-DB-2-BIDBUser].[etoro].Billing.vDeposit bd
 join BI_DB.[dbo].[BI_DB_UsageTracking_SF] sf
 on bd.CID = sf.CID
left join DWH.dbo.[Dim_Manager] bm
on bm.ManagerID = sf.CreatedByManagerID
where cast(bd.ModificationDate as date) = cast(getdate() as date)
and sf.CreatedDate_SF < bd.ModificationDate 
   and datediff(day,sf.CreatedDate_SF,bd.ModificationDate) <= 30
) a
where a.rn = 1