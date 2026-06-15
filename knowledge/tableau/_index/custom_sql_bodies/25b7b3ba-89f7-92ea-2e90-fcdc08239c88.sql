SELECT bdcmpfd.ActiveDate
,bdcmpfd.CID
,bdcmpfd.Region
,bdcmpfd.MoneyIn_Copy
,bdcmpfd.MoneyOut_Copy
,bdcmpfd.MoneyIn_CopyPortfolio
,bdcmpfd.MoneyOut_CopyPortfolio
,bdcmpfd.Count_Opened_Copy
,bdcmpfd.Count_Closed_Copy
,bdcmpfd.Count_Opened_CopyPortfolio
,bdcmpfd.Count_Closed_CopyPortfolio
,bdcmpfd.Active_Copy
,bdcmpfd.ActiveOpen_Copy
,bdcmpfd.AmountIn_NewTrades_Copy
FROM BI_DB..BI_DB_CID_MonthlyPanel_FullData bdcmpfd
WHERE bdcmpfd.ActiveDate>= DATEADD(MONTH,-5, DATEFROMPARTS(YEAR(GETDATE()-1),MONTH(GETDATE()-1),1))