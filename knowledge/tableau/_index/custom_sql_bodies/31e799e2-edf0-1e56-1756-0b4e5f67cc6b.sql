SELECT fd.Gender
      ,fm.ActiveDate
      ,COUNT(fm.CID) Users
      ,SUM(fm.Revenue_Total) Revenue
	  ,SUM(fm.PnL_Total	   ) PnL
	  ,SUM(fm.Active	   ) Active
	  ,SUM(fm.ActiveOpen   ) ActiveOpen
	  ,SUM(fm.Active_Copy  ) Active_Copy
          ,SUM(fm.EOM_Equity ) Equity
FROM [BI_DB].[dbo].[BI_DB_CID_MonthlyPanel_FullData] fm WITH (NOLOCK)
LEFT JOIN [BI_DB].[dbo].[BI_DB_CIDFirstDates] fd WITH (NOLOCK)
ON fm.CID = fd.CID
WHERE fm.ActiveDate  >= DATEADD(MONTH,-24,DATEFROMPARTS(YEAR(GETDATE()-1),MONTH(GETDATE()-1),1))
AND fm.IsFunded_New = 1
GROUP BY fd.Gender,fm.ActiveDate