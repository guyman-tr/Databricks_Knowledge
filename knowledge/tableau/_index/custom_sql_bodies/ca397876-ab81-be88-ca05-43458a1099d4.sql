SELECT  Regulation,
IsDLTUser,
	SUM (ISNULL (ClientBalanceRealizedPnL, 0)
		+ ISNULL (UnrealizedPnLChange, 0)
		- ISNULL (bdcbaln.ClientBalanceFullCommission, 0)
		- ISNULL (bdcbaln.UnrealizedFullCommissionChange, 0)) 
	  AS CBTotalZero,
DateID
FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New bdcbaln
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
group by Regulation,IsDLTUser, DateID