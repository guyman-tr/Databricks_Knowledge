SELECT
		CASE
			WHEN DATEADD(DAY, 7 - DATEPART(WEEKDAY, eft.TranDate), eft.TranDate) >= CAST(GETDATE()AS DATE) 
then CAST(GETDATE() -1 AS DATE)
			ELSE DATEADD(DAY, 7 - DATEPART(WEEKDAY, eft.TranDate), eft.TranDate )
		END AS Date
, Count(Distinct eft.GCID)Users
		
	FROM EXW.dbo.EXW_FactTransactions eft with (NOLOcK)
		 JOIN EXW.dbo.EXW_DimUser edu ON eft.GCID=edu.GCID AND edu.IsTestAccount=0
		WHERE eft.TranStatus = 'Verified' 
	 AND eft.TranDateID >=CAST(CONVERT (VARCHAR(8) , DATEADD(week, -5,CAST(DATEADD(week, DATEDIFF(week, -1, GETDATE()), -1) AS DATE))  , 112 ) AS INT)  --5 closed weeks befor current
    AND eft.TranDateID<    CAST(CONVERT(VARCHAR(8), getdate(), 112) AS INT)
AND eft.TranDate=DATEADD(DAY, 7 - DATEPART(WEEKDAY, eft.TranDate), eft.TranDate)--ONLY WEEKENDS
	GROUP BY
			CASE
			WHEN DATEADD(DAY, 7 - DATEPART(WEEKDAY, eft.TranDate), eft.TranDate) > =CAST(GETDATE()AS DATE)
then CAST(GETDATE() -1 AS DATE)
			ELSE DATEADD(DAY, 7 - DATEPART(WEEKDAY, eft.TranDate), eft.TranDate)
		END