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
dr.Name as DesignatedRegulation,
outcome.Name as Outcome,
CASE WHEN ad.IsFTD is not NULL then 'Depositors' else 'Non-depositors' end as "Depositors",
cc.VerificationLevelID,
dc.Name as Country,
case when dc.Name IN (
'United Arab Emirates',
'Taiwan',
'Kuwait',
'Thailand',
'Vietnam',
'Chile',
'Indonesia',
'Peru',
'Colombia',
'Bahrain',
'Saudi Arabia',
'Oman',
'Dominican Republic',
'Ecuador',
'Costa Rica',
'Uruguay',
'South Korea',
'Bolivia',
'Bangladesh',
'French Guiana') AND cc.DesignatedRegulationID=2
then 'Yes' else 'No' end as 'ASIC to FCA Country',
case  when dc.RiskGroupID in (1,2) THeN 'Rank 1 or 2 '
when vl.country_id IS NULL THEN '15 days' ELSE vl.verification_method end as "kycFlow"
from 
[BI_DB_dbo].[External_Assignment_Assignment_V_Tasks] tasks --
left join 
BI_DB_dbo.External_Assignment_BackOffice_Manager bm 
on bm.ManagerID=tasks.UpdatedBy
left join BI_DB_dbo.External_Assignment_BackOffice_Manager bm1 
on bm1.ManagerID=tasks.AssigneeID
left join BI_DB_dbo.External_Assignment_Dictionary_Outcome outcome 
on outcome.OutcomeID=tasks.OutcomeID
left join BI_DB_dbo.External_Assignment_Dictionary_OutcomeReason reason 
on reason.OutcomeReasonID=tasks.OutcomeReasonID
left join [BI_DB_dbo].[BI_DB_AllDeposits] ad on ad.CID=tasks.CID
and IsFTD=1
left join DWH_dbo.Dim_Customer cc on cc.RealCID=tasks.CID
left join DWH_dbo.Dim_Country dc on dc.CountryID=cc.CountryID
left join [BI_DB_dbo].[External_Fivetran_google_sheets_CountryVerificationLog] vl on vl.country_id=dc.CountryID
left join DWH_dbo.Dim_Regulation dr on dr.ID=cc.DesignatedRegulationID
where CreateDate>=dateadd(ww,-8,cast(getdate() as date))