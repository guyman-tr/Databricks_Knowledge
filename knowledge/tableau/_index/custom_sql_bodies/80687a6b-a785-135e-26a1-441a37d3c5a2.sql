SELECT a.ProcedureName
	 , a.EndDate AS LastCompletionDateTime
	 , a.Status
FROM 
(
SELECT
	osh.ProcedureName
  , osh.StartDate
  , osh.EndDate
  , CASE WHEN osh.ObjectStatus = 2 THEN 'Success' ELSE 'Failure' END AS Status
  , ROW_NUMBER () OVER (PARTITION BY osh.ProcedureName ORDER BY osh.StartDate desc) AS RN
FROM DE_dbo.ObjectsStatusHistory osh
WHERE osh.ProcedureName  like  '%SP_Deposit_Reversals_PIPs%'
	OR osh.ProcedureName like  '%SP_Withdraw_Rollback_PIPs%'
	OR osh.ProcedureName like  '%SP_PIPs_Report_MID_Settings%'
) a
WHERE a.RN = 1