SELECT 
    a.Club,
    DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1) AS ActiveDate,
    a.AccountManager,
    a.Contacted,
    SUM(CASE WHEN a.ActionType='Deposit from TP' THEN a.Amount ELSE 0 END) AS TotalDeposits_ThisMonth,
    SUM(CASE WHEN a.ActionType='Cashout from TP' THEN a.Amount ELSE 0 END) AS TotalCashouts_ThisMonth,
    SUM(CASE WHEN a.ActionType ='Deposit From IBAN' THEN a.Amount ELSE 0 END) AS TotalOpenfromIBAN_ThisMonth,
   SUM(CASE WHEN a.ActionType = 'Cashout From IBAN' THEN a.Amount ELSE 0 END) AS TotalClosetoIBAN_ThisMonth,
    SUM(CASE WHEN a.ActionType = 'Transfer In' THEN a.Amount ELSE 0 END) AS TotalCompensation_ThisMonth

FROM #united_MIMO a
group by a.Club,
    DATEFROMPARTS(YEAR(a.Date), MONTH(a.Date), 1) ,
    a.AccountManager,
    a.Contacted