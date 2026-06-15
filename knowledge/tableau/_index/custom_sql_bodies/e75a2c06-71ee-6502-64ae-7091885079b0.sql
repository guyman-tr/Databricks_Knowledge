SELECT
		CASE
			WHEN DATEADD(DAY, 7 - DATEPART(WEEKDAY, CAST(fca.Occurred AS DATE)), CAST(fca.Occurred AS DATE)) =
				 DATEADD(DAY, 7 - DATEPART(WEEKDAY, CAST(getdate()AS DATE)), CAST(getdate() AS DATE))
				 		THEN CAST(GETDATE()-1 AS DATE)
			ELSE  DATEADD(DAY, 7 - DATEPART(WEEKDAY, CAST(fca.Occurred AS DATE)), CAST(fca.Occurred AS DATE)) 
		END AS Date
    
 , COUNT(DISTINCT fca.GCID) Logins
 FROM   DWH..Fact_CustomerAction fca WITH (NOLOCK)  
 JOIN DWH..Dim_Product p   ON fca.PlatformID = p.ProductID
 WHERE fca.ActionTypeID=14 AND p.ProductID IN ( 118,119, 120)  
 AND  fca.RealCID NOT IN ( SELECT etu.RealCID FROM EXW.dbo.EXW_TestUsers etu)
 AND  DateID BETWEEN 
   CAST(CONVERT(VARCHAR(8), DATEADD(week, -5,  DATEADD(DD,-(DATEPART(DW,CAST(GETDATE()AS DATE))-7),CAST(GETDATE()AS DATE))  ) , 112) AS INT) 
  AND CAST(CONVERT(VARCHAR(8), GETDATE(), 112) AS INT) 

 GROUP BY  CASE
			WHEN DATEADD(DAY, 7 - DATEPART(WEEKDAY, CAST(fca.Occurred AS DATE)), CAST(fca.Occurred AS DATE)) =
				 DATEADD(DAY, 7 - DATEPART(WEEKDAY, CAST(getdate()AS DATE)), CAST(getdate() AS DATE))
				 		THEN CAST(GETDATE()-1 AS DATE)
			ELSE  DATEADD(DAY, 7 - DATEPART(WEEKDAY, CAST(fca.Occurred AS DATE)), CAST(fca.Occurred AS DATE)) 
		END