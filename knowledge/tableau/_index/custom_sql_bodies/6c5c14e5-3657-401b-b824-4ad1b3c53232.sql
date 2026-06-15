SELECT a.AccountNumber
	   ,COALESCE( a.CID, b.CID) AS CID
	   ,COALESCE(a.EntryDate,b.Date) AS Date
	   ,COALESCE(a.CUSIP,b.CUSIP) AS CUSIP
	   ,COALESCE(a.Category,b.Category) AS 	Category
	   ,a.Trailer AS ApexTrailer
	   ,a.TerminalID
	   ,COALESCE(abs(a.Units),b.RoundeUnits) AS Units
	   ,b.InstrumentDisplayName
	   ,b.ExactUnits AS eToroExactUnits
       ,CASE WHEN a.CID IS NULL THEN 'Missing in Apex'
     		 WHEN  b.CID IS NULL THEN 'Missing in eToro' ELSE 'Exists in Both' END 'ReconciliationStatus'

FROM  BI_DB.[dbo].[BI_DB_US_Apex_Stocks_Activity_Apex] a
FULL OUTER  JOIN    BI_DB.[dbo].[BI_DB_US_Apex_Stocks_Activity_eToroDB] b 
ON 	a.CID=b.CID AND a.Category = b.Category AND a.CUSIP = b.CUSIP 
and abs(a.Units)=b.RoundeUnits
AND a.EntryDate BETWEEN DATEADD(DAY, -1,b.Date) AND  DATEADD(DAY, 1,b.Date)
where COALESCE(a.EntryDate,b.Date)>=<[Parameters].[Parameter 1]>