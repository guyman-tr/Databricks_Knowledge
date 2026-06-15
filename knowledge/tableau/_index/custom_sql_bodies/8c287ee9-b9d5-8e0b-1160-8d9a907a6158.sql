select 
at1.*,
DC.VerificationLevelID,
case when  [VerificationLevel3Date]>=CreateDate then 'L3Upload'
else 'Others' end AS 'L3Upload'
from [BI_DB_dbo].[BI_DB_AssignmentToolTasks] at1
join DWH_dbo.Dim_Customer DC ON DC.RealCID=at1.CID
left join #firstVer f on f.CID=at1.CID