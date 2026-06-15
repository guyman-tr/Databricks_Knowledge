SELECT MonthName	  
      ,RealCID
	  ,GCID
	  ,Phone
	  ,Country
	  ,Desk
      ,LastContantact
	  ,AM
      ,TotalCoAmount      
FROM(
SELECT MonthName	  
      ,RealCID
	  ,GCID
	  ,Phone
	  ,Country
	  ,Desk
      ,LastContantact
	  ,AM
      ,TotalCoAmount      
,ROW_NUMBER() OVER (PARTITION BY Desk,MonthName ORDER BY TotalCoAmount DESC) rn
FROM(
SELECT dd.MonthNameAbbreviation + ' '+CONVERT(VARCHAR(10),dd.CalendarYear) MonthName	  
      ,ca.RealCID
	  ,ca.GCID
	  ,dc.Phone
	  ,dc1.Name Country
	  ,CASE WHEN dc1.Name = 'Russia' then 'Russia' ELSE dc1.Desk END Desk
      ,LastContantact
	  ,CONCAT(dm.FirstName,' ',dm.LastName) AM
      ,SUM(CASE WHEN ca.ActionTypeID = 8 THEN ca.Amount ELSE 0 END) AS TotalCoAmount      
       FROM DWH.dbo.Fact_CustomerAction ca WITH(NOLOCK) 
	   INNER JOIN [DWH].[dbo].[Dim_Customer] dc
	   ON ca.RealCID = dc.RealCID
	   INNER JOIN [DWH].[dbo].[Dim_Country] dc1 
	   ON dc.CountryID = dc1.CountryID
	   INNER JOIN [DWH].[dbo].[Dim_Date] dd WITH (NOLOCK)
       ON ca.DateID = dd.DateKey
	   LEFT JOIN DWH..Dim_Manager dm
	   ON dc.AccountManagerID = dm.ManagerID
  OUTER APPLY 
(
SELECT CID
      ,MAX(CreatedDate_SF) LastContantact
FROM [BI_DB].[dbo].[BI_DB_UsageTracking_SF] ut WITH (NOLOCK)
WHERE ActionName = 'Phone_Call_Succeed__c'
AND ut.CID = ca.RealCID
GROUP BY CID
)c
WHERE ca.ActionTypeID = 8 --Redeemed And Non-Redeemed Cashouts  
AND DateID  >= CONVERT(CHAR(8),DATEADD(Month,DATEDIFF(Month,0,GETDATE())-1,0),112)
AND DateID  < CONVERT(CHAR(8),DATEADD(Month,DATEDIFF(Month,0,GETDATE()),0),112)
       GROUP BY ca.RealCID  
			   ,dd.MonthNameAbbreviation + ' '+CONVERT(VARCHAR(10),dd.CalendarYear)
			   ,ca.GCID
			   ,dc.Phone
	           ,dc1.Name 
			   ,CASE WHEN dc1.Name = 'Russia' then 'Russia' ELSE dc1.Desk END
			   ,LastContantact
			   ,CONCAT(dm.FirstName,' ',dm.LastName)
)q1
)q2
WHERE rn <= 60