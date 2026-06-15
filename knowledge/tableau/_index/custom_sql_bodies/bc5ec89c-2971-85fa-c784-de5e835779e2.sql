SELECT 
bw.WithdrawID,
bw.CID,
bw.Amount_Withdraw as Amount,
--CASE WHEN bw.Amount>100000 THEN '>>100k' ELSE '<<100k' END AS [Group],
bw.RequestDate,
cs.Name AS CashoutStatus,
cr.Name AS CashoutReason,
M.FirstName + ' ' + M.LastName AS Manager,
u.Site as Country 
FROM DWH_dbo.Fact_BillingWithdraw bw
JOIN DWH_dbo.Dim_CashoutStatus cs ON cs.CashoutStatusID=bw.CashoutStatusID_Withdraw
LEFT JOIN DWH_dbo.Dim_CashoutReason cr ON cr.CashoutReasonID=bw.CashoutReasonID
JOIN BI_DB_dbo.External_etoro_Billing_Withdraw ebw on ebw.WithdrawID=bw.WithdrawID
LEFT JOIN  DWH_dbo.Dim_Manager M ON M.ManagerID=ebw.ManagerID
left join  [BI_DB_dbo].[External_BI_OUTPUT_Customer_Customer_Support_Agent_User] u on u.AccountManagerID=ebw.ManagerID
WHERE 
bw.CashoutReasonID =16 --Requested by User
AND bw.CashoutStatusID_Withdraw =3 --Processed
--AND DATEDIFF(DAY,bw.RequestDate,GETDATE())<=7
and (u.Site='Australia'or u.Country='Singapore')