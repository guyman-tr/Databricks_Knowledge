SELECT MonthName
      ,RealCID
      ,GCID
	  ,Phone
	  ,Country
      ,Desk
	  ,Manager
	  ,LastContantact
      ,Deposit
	 
FROM
(
SELECT MonthName
      ,RealCID
      ,GCID
	  ,Phone
	  ,Country
      ,Desk
	  ,Manager
	  ,LastContantact
      ,Deposit
	  ,ROW_NUMBER() OVER (PARTITION BY Desk,MonthName ORDER BY Deposit DESC) rn
FROM
(
SELECT dd.MonthNameAbbreviation + ' '+CONVERT(VARCHAR(10),dd.CalendarYear) MonthName
      ,b.RealCID
      ,dc.GCID
	  ,dc.Phone
	  ,b.Country
      ,CASE WHEN b.Country = 'Russia' then 'Russia' ELSE b.Desk END Desk
	  ,b.Manager
	  ,c.LastContantact
      ,SUM(b.TotalDepositAmount) Deposit
  FROM [BI_DB].[dbo].[BI_DB_NewBonusReport] b WITH (NOLOCK)
  INNER JOIN [DWH].[dbo].[Dim_Customer] dc WITH (NOLOCK)
  ON b.RealCID = dc.RealCID
  INNER JOIN [DWH].[dbo].[Dim_Date] dd WITH (NOLOCK)
  ON b.DateID = dd.DateKey
  OUTER APPLY 
(
SELECT CID
      ,MAX(CreatedDate_SF) LastContantact
FROM [BI_DB].[dbo].[BI_DB_UsageTracking_SF] ut WITH (NOLOCK)
WHERE ActionName = 'Phone_Call_Succeed__c'
AND ut.CID = b.RealCID
GROUP BY CID
)c
  WHERE DateID  >= CONVERT(CHAR(8),DATEADD(Month,DATEDIFF(Month,0,GETDATE())-1,0),112)
  AND DateID  < CONVERT(CHAR(8),DATEADD(Month,DATEDIFF(Month,0,GETDATE()),0),112)
  GROUP BY  b.RealCID
      ,dc.GCID
	  ,dc.Phone
	  ,b.Country
      ,b.Desk
	  ,b.Manager
	  ,c.LastContantact
	  ,dd.MonthNameAbbreviation + ' '+CONVERT(VARCHAR(10),dd.CalendarYear)
)q1
)q2

WHERE rn <=40