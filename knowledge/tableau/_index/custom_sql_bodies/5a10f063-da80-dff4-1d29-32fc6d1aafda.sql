SELECT 
bw.WithdrawID,
bw.CID,
bw.Amount,
CASE WHEN bw.Amount>100000 THEN '>100k' ELSE '<100k' END AS [Group],
bw.RequestDate,
cs.Name AS CashoutStatus,
cr.Name AS CashoutReason,
M.FirstName + ' ' + M.LastName AS Manager

FROM [BI_DB_dbo].[External_etoro_Billing_Withdraw] bw
JOIN DWH_dbo.Dim_CashoutStatus cs ON cs.CashoutStatusID=bw.CashoutStatusID
LEFT JOIN [BI_DB_dbo].[External_etoro_Dictionary_CashoutReason] cr ON cr.CashoutReasonID=bw.CashoutReasonID
LEFT JOIN  DWH_dbo.Dim_Manager M ON M.ManagerID=bw.ManagerID
WHERE 
bw.CashoutReasonID <>16 --Requested by User
AND bw.CashoutStatusID <>3 --Processed
AND DATEDIFF(DAY,bw.RequestDate,GETDATE())<=7