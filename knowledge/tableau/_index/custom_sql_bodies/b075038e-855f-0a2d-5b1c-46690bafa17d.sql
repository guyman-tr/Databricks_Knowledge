select tasks.* ,  
CASE WHEN tasks.OutcomeID in (3) AND tasks.IsActive=1 THEN 
bm1.FirstName + ' ' + bm1.LastName
when tasks.OutcomeID=7 and tasks.AssigneeID=-1 
then bm.FirstName + ' ' + bm.LastName 
WHEN (tasks.OutcomeID is NULL or tasks.OutcomeID=0)
and tasks.IsActive=1 then 
bm1.FirstName + ' ' + bm1.LastName 
WHEN (tasks.OutcomeID is not NULL and tasks.IsActive=0)or 
(tasks.OutcomeID<>0 AND tasks.IsActive=0)
then 
bm.FirstName + ' ' + bm.LastName 
else bm.FirstName + ' ' + bm.LastName 
end as HandledBy, 
outcome.Name as Outcome,
CASE WHEN ad.IsFTD is not NULL then 'Depositors' else 'Non-depositors' end as "Depositors",
cc.VerificationLevelID,
dc.Name as Country
from [BI_DB_dbo].[External_Assignment_Assignment_V_Tasks]  tasks --
left join BI_DB_dbo.External_Assignment_BackOffice_Manager bm on bm.ManagerID=tasks.UpdatedBy
left join BI_DB_dbo.External_Assignment_BackOffice_Manager bm1 on bm1.ManagerID=tasks.AssigneeID
left join BI_DB_dbo.External_Assignment_Dictionary_Outcome outcome on outcome.OutcomeID=tasks.OutcomeID
left join BI_DB_dbo.External_Assignment_Dictionary_OutcomeReason reason on reason.OutcomeReasonID=tasks.OutcomeReasonID
left join [BI_DB_dbo].[BI_DB_AllDeposits] ad on ad.CID=tasks.CID
and IsFTD=1
left join DWH_dbo.Dim_Customer cc on cc.RealCID=tasks.CID
left join DWH_dbo.Dim_Country dc on dc.CountryID=cc.CountryID
where CreateDate>=dateadd(ww,-23,cast(getdate() as date))