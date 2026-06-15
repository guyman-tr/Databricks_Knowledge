SELECT 
    dpl.Name AS Club,
'Deposit From TP' as 'ActionType',
    DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1) AS ActiveDate,

    dm.FirstName + ' ' + dm.LastName AccountManager,
    a.Contacted,
 a.RealCID,
da.Name AccountType,
a.Date,
   -- SUM(CASE WHEN a.ActionType = 'Compensation' THEN a.Amount ELSE 0 END) AS TotalCompensation_ThisMonth,
SUM(CASE WHEN a.ActionType = 'Deposit' and a.FundingTypeID<>33 THEN a.Amount ELSE 0 END) AS Amount
--SUM(CASE WHEN a.ActionType = 'Cashout' and a.FundingTypeID<>33 THEN a.Amount ELSE 0 END) AS TotalCashouts_ThisMonth_without_IBAN

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
join DWH_dbo.Dim_AccountType da on da.AccountTypeID=dc.AccountTypeID
WHERE  bdcdpc.CurrentTier >= 6
AND dc.IsValidCustomer = 1
and a.FundingTypeID<>33
and a.ActionType = 'Deposit' 
GROUP BY dpl.Name,
         DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1),
         dm.FirstName + ' ' + dm.LastName,
		 a.Contacted,
            a.RealCID,da.Name,a.Date

UNION ALL

SELECT 
    bdcdpc.EOD_Club AS Club,
'Deposit From TP' as 'ActionType',
    DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1) AS ActiveDate,
	bdcdpc.AccountManager,
    a.Contacted,
a.RealCID,
da.Name AccountType,
a.Date,
    --SUM(CASE WHEN a.ActionType = 'Deposit' THEN a.Amount ELSE 0 END) AS TotalDeposits_ThisMonth,
    --SUM(CASE WHEN a.ActionType = 'Cashout' THEN a.Amount ELSE 0 END) AS TotalCashouts_ThisMonth,
    --SUM(CASE WHEN a.ActionType = 'Compensation' THEN a.Amount ELSE 0 END) AS TotalCompensation_ThisMonth,
SUM(CASE WHEN a.ActionType = 'Deposit' and a.FundingTypeID<>33 THEN a.Amount ELSE 0 END) AS Amount
--SUM(CASE WHEN a.ActionType = 'Cashout' and a.FundingTypeID<>33 THEN a.Amount ELSE 0 END) AS TotalCashouts_ThisMonth_without_IBAN


FROM #Action a
JOIN BI_DB_dbo.BI_DB_CID_DailyPanel_FullData bdcdpc
    ON a.DateID = bdcdpc.DateID
    AND bdcdpc.CID = a.RealCID
JOIN DWH_dbo.Dim_Customer dc
    ON a.RealCID = dc.RealCID
join DWH_dbo.Dim_AccountType da on da.AccountTypeID=dc.AccountTypeID

WHERE dc.AccountTypeID = 2
AND bdcdpc.EOD_Club NOT IN ('Platinum Plus', 'Diamond')
AND dc.IsValidCustomer = 1
and a.FundingTypeID<>33
and a.ActionType = 'Deposit'
GROUP BY bdcdpc.EOD_Club,
         DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1),
         bdcdpc.AccountManager,
		 a.Contacted,a.RealCID,da.Name,a.Date

union all

SELECT 
    dpl.Name AS Club,
'Transfer In' as 'ActionType',
    DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1) AS ActiveDate,
    dm.FirstName + ' ' + dm.LastName AccountManager,
    a.Contacted,
a.RealCID,
da.Name AccountType,
a.Date,
    SUM(CASE WHEN a.ActionType = 'Compensation' THEN a.Amount ELSE 0 END) AS Amount


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
join DWH_dbo.Dim_AccountType da on da.AccountTypeID=dc.AccountTypeID
WHERE  bdcdpc.CurrentTier >= 6
AND dc.IsValidCustomer = 1
and a.ActionType = 'Compensation'
GROUP BY dpl.Name,
         DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1),
         dm.FirstName + ' ' + dm.LastName,
		 a.Contacted,a.RealCID,da.Name,a.Date
UNION ALL

SELECT 
    bdcdpc.EOD_Club AS Club,
'Transfer In' as 'ActionType',
    DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1) AS ActiveDate,
	bdcdpc.AccountManager,
    a.Contacted,
a.RealCID,
da.Name AccountType,
a.Date,
    SUM(CASE WHEN a.ActionType = 'Compensation' THEN a.Amount ELSE 0 END) AS Amount



FROM #Action a
JOIN BI_DB_dbo.BI_DB_CID_DailyPanel_FullData bdcdpc
    ON a.DateID = bdcdpc.DateID
    AND bdcdpc.CID = a.RealCID
JOIN DWH_dbo.Dim_Customer dc
    ON a.RealCID = dc.RealCID
join DWH_dbo.Dim_AccountType da on da.AccountTypeID=dc.AccountTypeID
WHERE dc.AccountTypeID = 2
AND bdcdpc.EOD_Club NOT IN ('Platinum Plus', 'Diamond')
AND dc.IsValidCustomer = 1
and a.ActionType = 'Compensation'
GROUP BY bdcdpc.EOD_Club,
         DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1),
         bdcdpc.AccountManager,
		 a.Contacted,a.RealCID,da.Name,a.Date

union all 
--IBAN---
SELECT 
    dpl.Name AS Club,
'Deposit From IBAN' as 'ActionType',
    DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1) AS ActiveDate,
    dm.FirstName + ' ' + dm.LastName AccountManager,
    a.Contacted,
a.RealCID,
da.Name AccountType,
a.Date,
    SUM(CASE WHEN a.MIMOAction = 'Deposit' THEN a.AmountUSD ELSE 0 END) AS Amount


FROM #MIMO_IBAN a
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
join DWH_dbo.Dim_AccountType da on da.AccountTypeID=dc.AccountTypeID
WHERE  bdcdpc.CurrentTier >= 6
AND dc.IsValidCustomer = 1
and a.MIMOAction = 'Deposit'
GROUP BY dpl.Name,
         DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1),
         dm.FirstName + ' ' + dm.LastName,
		 a.Contacted,a.RealCID,da.Name,a.Date
UNION ALL

SELECT 
    bdcdpc.EOD_Club AS Club,
'Deposit From IBAN' as 'ActionType',
    DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1) AS ActiveDate,
	bdcdpc.AccountManager,
    a.Contacted,
a.RealCID,
da.Name AccountType,
a.Date,
SUM(CASE WHEN a.MIMOAction = 'Deposit' THEN a.AmountUSD ELSE 0 END) AS Amount
--SUM(CASE WHEN a.MIMOAction = 'Withdraw' THEN a.AmountUSD ELSE 0 END) AS TotalCashouts_ThisMonth_IBAN


FROM #MIMO_IBAN a
JOIN BI_DB_dbo.BI_DB_CID_DailyPanel_FullData bdcdpc
    ON a.DateID = bdcdpc.DateID
    AND bdcdpc.CID = a.RealCID
JOIN DWH_dbo.Dim_Customer dc
    ON a.RealCID = dc.RealCID
join DWH_dbo.Dim_AccountType da on da.AccountTypeID=dc.AccountTypeID

WHERE dc.AccountTypeID = 2
AND bdcdpc.EOD_Club NOT IN ('Platinum Plus', 'Diamond')
AND dc.IsValidCustomer = 1
and a.MIMOAction = 'Deposit'
GROUP BY bdcdpc.EOD_Club,
         DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1),
         bdcdpc.AccountManager,
		 a.Contacted,a.RealCID,da.Name,a.Date
union all 

SELECT 
    dpl.Name AS Club,
'Cashout From TP' as 'ActionType',
    DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1) AS ActiveDate,
    dm.FirstName + ' ' + dm.LastName AccountManager,
    a.Contacted,
a.RealCID,
da.Name AccountType,
a.Date,
   -- SUM(CASE WHEN a.ActionType = 'Deposit' THEN a.Amount ELSE 0 END) AS TotalDeposits_ThisMonth,
    --SUM(CASE WHEN a.ActionType = 'Cashout' THEN a.Amount ELSE 0 END) AS TotalCashouts_ThisMonth,
    --SUM(CASE WHEN a.ActionType = 'InternalDeposit' THEN a.Amount ELSE 0 END) AS TotalOpenfromIBAN_ThisMonth,
    --SUM(CASE WHEN a.ActionType = 'InternalWithdraw' THEN a.Amount ELSE 0 END) AS TotalClosetoIBAN_ThisMonth,
    --SUM(CASE WHEN a.ActionType = 'Compensation' THEN a.Amount ELSE 0 END) AS TotalCompensation_ThisMonth,
--SUM(CASE WHEN a.ActionType = 'Deposit' and a.FundingTypeID<>33 THEN a.Amount ELSE 0 END) AS TotalDeposits_ThisMonth_without_IBAN
SUM(CASE WHEN a.ActionType = 'Cashout' and a.FundingTypeID<>33 THEN a.Amount ELSE 0 END) AS Amount

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
join DWH_dbo.Dim_AccountType da on da.AccountTypeID=dc.AccountTypeID

WHERE  bdcdpc.CurrentTier >= 6
AND dc.IsValidCustomer = 1
and a.ActionType = 'Cashout' 
and a.FundingTypeID<>33
GROUP BY dpl.Name,
         DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1),
         dm.FirstName + ' ' + dm.LastName,
		 a.Contacted,a.RealCID,da.Name,a.Date
UNION ALL

SELECT 
    bdcdpc.EOD_Club AS Club,
'Cashout From TP' as 'ActionType',
    DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1) AS ActiveDate,
	bdcdpc.AccountManager,
    a.Contacted,
a.RealCID,
da.Name AccountType,
a.Date,
    --SUM(CASE WHEN a.ActionType = 'Deposit' THEN a.Amount ELSE 0 END) AS TotalDeposits_ThisMonth,
    --SUM(CASE WHEN a.ActionType = 'Cashout' THEN a.Amount ELSE 0 END) AS TotalCashouts_ThisMonth,
  --  SUM(CASE WHEN a.ActionType = 'Compensation' THEN a.Amount ELSE 0 END) AS TotalCompensation_ThisMonth,
--SUM(CASE WHEN a.ActionType = 'Deposit' and a.FundingTypeID<>33 THEN a.Amount ELSE 0 END) AS TotalDeposits_ThisMonth_without_IBAN
SUM(CASE WHEN a.ActionType = 'Cashout' and a.FundingTypeID<>33 THEN a.Amount ELSE 0 END) AS Amount


FROM #Action a
JOIN BI_DB_dbo.BI_DB_CID_DailyPanel_FullData bdcdpc
    ON a.DateID = bdcdpc.DateID
    AND bdcdpc.CID = a.RealCID
JOIN DWH_dbo.Dim_Customer dc
    ON a.RealCID = dc.RealCID
join DWH_dbo.Dim_AccountType da on da.AccountTypeID=dc.AccountTypeID
WHERE dc.AccountTypeID = 2
AND bdcdpc.EOD_Club NOT IN ('Platinum Plus', 'Diamond')
AND dc.IsValidCustomer = 1
and a.ActionType = 'Cashout' 
and a.FundingTypeID<>33
GROUP BY bdcdpc.EOD_Club,
         DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1),
         bdcdpc.AccountManager,
		 a.Contacted,a.RealCID,da.Name,a.Date

union all
--IBAN Cashout---
SELECT 
    dpl.Name AS Club,

'Cashout From IBAN' as 'ActionType',
    DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1) AS ActiveDate,
    dm.FirstName + ' ' + dm.LastName AccountManager,
    a.Contacted,
a.RealCID,
da.Name AccountType,
a.Date,
    --SUM(CASE WHEN a.MIMOAction = 'Deposit' THEN a.AmountUSD ELSE 0 END) AS TotalDeposits_ThisMonth_IBAN
    SUM(CASE WHEN a.MIMOAction = 'Withdraw' THEN a.AmountUSD ELSE 0 END) AS Amount

FROM #MIMO_IBAN a
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
join DWH_dbo.Dim_AccountType da on da.AccountTypeID=dc.AccountTypeID
WHERE  bdcdpc.CurrentTier >= 6
AND dc.IsValidCustomer = 1
and a.MIMOAction = 'Withdraw'
GROUP BY dpl.Name,
         DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1),
         dm.FirstName + ' ' + dm.LastName,
		 a.Contacted,a.RealCID,da.Name,a.Date
UNION ALL

SELECT 
    bdcdpc.EOD_Club AS Club,
'Cashout From IBAN' as 'ActionType',
    DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1) AS ActiveDate,
	bdcdpc.AccountManager,
    a.Contacted,
a.RealCID,
da.Name AccountType,
a.Date,
--SUM(CASE WHEN a.MIMOAction = 'Deposit' THEN a.AmountUSD ELSE 0 END) AS TotalDeposits_ThisMonth_IBAN
SUM(CASE WHEN a.MIMOAction = 'Withdraw' THEN a.AmountUSD ELSE 0 END) AS Amount


FROM #MIMO_IBAN a
JOIN BI_DB_dbo.BI_DB_CID_DailyPanel_FullData bdcdpc
    ON a.DateID = bdcdpc.DateID
    AND bdcdpc.CID = a.RealCID
JOIN DWH_dbo.Dim_Customer dc
    ON a.RealCID = dc.RealCID
join DWH_dbo.Dim_AccountType da on da.AccountTypeID=dc.AccountTypeID
WHERE dc.AccountTypeID = 2
AND bdcdpc.EOD_Club NOT IN ('Platinum Plus', 'Diamond')
AND dc.IsValidCustomer = 1
and a.MIMOAction = 'Withdraw'
GROUP BY bdcdpc.EOD_Club,
         DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1),
         bdcdpc.AccountManager,
		 a.Contacted,a.RealCID,da.Name,a.Date