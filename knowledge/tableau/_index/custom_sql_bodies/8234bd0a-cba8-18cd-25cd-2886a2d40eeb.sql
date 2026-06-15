SELECT dpl.Name Club
		,DATEFROMPARTS(YEAR(a.Date),MONTH(a.Date),1) ActiveDate
--		,dco.MarketingRegionManualName Region
		,SUM(CASE WHEN a.ActionType = 'Deposit' THEN a.Amount ELSE 0 END) TotalDeposits_ThisMonth
		,SUM(CASE WHEN a.ActionType = 'Cashout' THEN a.Amount ELSE 0 END)  TotalCashouts_ThisMonth
		,SUM(CASE WHEN a.ActionType = 'InternalDeposit' THEN a.Amount ELSE 0 END)  TotalOpenfromIBAN_ThisMonth 
		,SUM(CASE WHEN a.ActionType = 'InternalWithdraw' THEN a.Amount ELSE 0 END)  TotalClosetoIBAN_ThisMonth 
		,dm.FirstName + ' ' + dm.LastName AccountManager
FROM #Action a
JOIN BI_DB_dbo.BI_DB_CID_DailyPanel_Club bdcdpc
ON a.DateID = bdcdpc.DateID
AND bdcdpc.CID = a.RealCID
JOIN DWH_dbo.Dim_PlayerLevel dpl
ON dpl.PlayerLevelID = bdcdpc.CurrentTier
JOIN DWH_dbo.Dim_Customer dc
ON a.RealCID = dc.RealCID
JOIN DWH_dbo.Dim_Country dco
ON bdcdpc.CountryID = dco.CountryID
JOIN DWH_dbo.Dim_Manager dm
ON dm.ManagerID = bdcdpc.AccountManagerID
WHERE bdcdpc.CurrentTier>=6 
AND dc.IsValidCustomer = 1
GROUP BY dpl.Name 
		,DATEFROMPARTS(YEAR(a.Date),MONTH(a.Date),1)
--		,dco.MarketingRegionManualName
		,dm.FirstName + ' ' + dm.LastName
		
UNION ALL

SELECT bdcdpc.EOD_Club Club
		,DATEFROMPARTS(YEAR(a.Date),MONTH(a.Date),1) ActiveDate
--		,dco.MarketingRegionManualName Region
		,SUM(CASE WHEN a.ActionType = 'Deposit' THEN a.Amount ELSE 0 END) TotalDeposits_ThisMonth
		,SUM(CASE WHEN a.ActionType = 'Cashout' THEN a.Amount ELSE 0 END)  TotalCashouts_ThisMonth 
		,SUM(CASE WHEN a.ActionType = 'InternalDeposit' THEN a.Amount ELSE 0 END)  TotalOpenfromIBAN_ThisMonth 
		,SUM(CASE WHEN a.ActionType = 'InternalWithdraw' THEN a.Amount ELSE 0 END)  TotalClosetoIBAN_ThisMonth 
		,bdcdpc.AccountManager
FROM #Action a
JOIN BI_DB_dbo.BI_DB_CID_DailyPanel_FullData bdcdpc
ON a.DateID = bdcdpc.DateID
AND bdcdpc.CID = a.RealCID
JOIN DWH_dbo.Dim_Customer dc
ON a.RealCID = dc.RealCID
WHERE  dc.AccountTypeID = 2
AND bdcdpc.EOD_Club NOT IN ('Platinum Plus','Diamond')
AND dc.IsValidCustomer = 1
GROUP BY bdcdpc.EOD_Club 
		,DATEFROMPARTS(YEAR(a.Date),MONTH(a.Date),1)
--		,dco.MarketingRegionManualName
		,bdcdpc.AccountManager