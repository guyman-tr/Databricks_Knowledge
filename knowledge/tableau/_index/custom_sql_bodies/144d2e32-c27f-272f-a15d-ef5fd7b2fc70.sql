Select 
bm.FirstName +' '+ bm.LastName as fullName,
t.TaskID,
 t.ManagerID,
 t.CID,
 O.Name as Outcome,
 t.OutcomeDate,
 t.[Priority]
from
(select A.ManagerID, A.TaskID, t.CID, A.OutcomeID, A.OutcomeDate, t.[Priority]
from BI_DB_dbo.External_Assignment_Assignment_TaskAudit A
JOIN [BI_DB_dbo].[External_Assignment_Assignment_V_Tasks] t ON t.TaskID=A.TaskID
where CAST (OutcomeDate AS DATE ) BETWEEN <[Parameters].[Parameter 1]>AND <[Parameters].[Parameter 2]>
AND A.OutcomeID not in (11)
and cast(OutcomeDate as date)>='2024-01-01'
) t

join [BI_DB_dbo].[External_etoro_BackOffice_Manager] bm on bm.ManagerID = t.ManagerID
JOIN [BI_DB_dbo].[External_Assignment_Dictionary_Outcome] O ON O.OutcomeID=t.OutcomeID