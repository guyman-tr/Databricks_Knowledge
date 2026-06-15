SELECT dd.CalendarYear
      ,dd.FullDate
      ,fm.EOM_Club Club
	  ,COUNT(fm.CID) Customers
	  ,SUM(EOM_Equity) EOM_Equity
           --,SUM(fm.EOM_Equity_Copy + fm.EOM_Equity_Real_Crypto + fm.EOM_Equity_CFD_Crypto+ fm.EOM_Equity_Real_Stocks + fm.EOM_Equity_CFD_Stocks+fm.[EOM_Equity_FX/Comm/Ind]) EOM_Equity
FROM [BI_DB].[dbo].[BI_DB_CID_MonthlyPanel_FullData] fm WITH (NOLOCK)
INNER JOIN [DWH].[dbo].[Dim_Date] dd WITH (NOLOCK)
ON fm.ActiveDate = dd.FullDate
WHERE  fm.IsFunded_New = 1
AND	dd.MonthNumberOfQuarter = 3
GROUP BY dd.CalendarYear
      ,dd.FullDate
      ,fm.EOM_Club