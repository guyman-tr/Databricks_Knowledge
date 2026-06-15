select
 a.*
 ,dc.VerificationLevelID
 ,dc.FirstDepositDate
 ,case 
	when Year(dc.FirstDepositDate) = 1900 then 'No'
	else 'Yes'
  end as 'IsFTD'
 ,case 
	when dc.IsDepositor = 0 then 'No' 
	else 'Yes'
  end as 'IsDepositor'
from 
	[BI_DB_dbo].[BI_DB_AssignmentToolTasks] a
LEFT JOIN
	DWH_dbo.Dim_Customer dc on dc.RealCID = a.CID