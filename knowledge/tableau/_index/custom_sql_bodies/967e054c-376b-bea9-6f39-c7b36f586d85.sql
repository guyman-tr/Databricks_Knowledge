SELECT Gain_12M.RealCID,
		Gain_12M.Performance_12m,
		Gain_24M.Performance_24m,
		Gain_36M.Performance_36m,
		Gain_48M.Performance_48m,
		Gain_60M.Performance_60m
FROM (
		SELECT RealCID,
			   FORMAT(COALESCE(Gain_12M.Performance_12m, 1)-1,'P') AS Performance_12m
		FROM (
			   SELECT RealCID,
					  EXP(SUM(LOG(Gain_New))) AS Performance_12m 
			   FROM (
					  SELECT RealCID
							 ,[Year]*100+[Month] YearMonth
							 ,CONVERT(DECIMAL(10,2),Gain) Gain_P
							 ,CASE WHEN 1+(CONVERT(DECIMAL(10,2),Gain)/100)<=0 THEN 0.00001 ELSE 1+(CONVERT(DECIMAL(10,2),Gain)/100) END Gain_New
					   FROM BI_DB_dbo.BI_DB_PI_Gain
					   WHERE TimeFarme='M' 
							AND [Year]*100+[Month] BETWEEN YEAR(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -12,GETDATE())), 0))*100+
														   MONTH(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -12,GETDATE())), 0)) 
														   AND
														   YEAR(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -1,GETDATE())), 0))*100+
														   MONTH(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -1,GETDATE())), 0))
					 )Gain_12m
			
				GROUP BY RealCID
								) AS Gain_12M
											  ) AS Gain_12M
JOIN (
		SELECT RealCID,
			   FORMAT(COALESCE(Gain_24M.Performance_24m, 1)-1,'P') AS Performance_24m
		FROM (
			   SELECT RealCID,
					  EXP(SUM(LOG(Gain_New))) AS Performance_24m 
			   FROM (
					  SELECT RealCID
							 ,[Year]*100+[Month] YearMonth
							 ,CONVERT(DECIMAL(10,2),Gain) Gain_P
							 ,CASE WHEN 1+(CONVERT(DECIMAL(10,2),Gain)/100)<=0 THEN 0.00001 ELSE 1+(CONVERT(DECIMAL(10,2),Gain)/100) END Gain_New
					   FROM BI_DB_dbo.BI_DB_PI_Gain
					   WHERE TimeFarme='M' 
							AND [Year]*100+[Month] BETWEEN YEAR(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -24,GETDATE())), 0))*100+
														   MONTH(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -24,GETDATE())), 0)) 
														   AND
														   YEAR(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -1,GETDATE())), 0))*100+
														   MONTH(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -1,GETDATE())), 0))
					 )Gain_24m
				GROUP BY RealCID
								) AS Gain_24M
											) AS Gain_24M
	ON Gain_12M.RealCID=Gain_24M.RealCID
JOIN (
		SELECT RealCID,
			   FORMAT(COALESCE(Gain_36M.Performance_36m, 1)-1,'P') AS Performance_36m
		FROM (
			   SELECT RealCID,
					  EXP(SUM(LOG(Gain_New))) AS Performance_36m 
			   FROM (
					  SELECT RealCID
							 ,[Year]*100+[Month] YearMonth
							 ,CONVERT(DECIMAL(10,2),Gain) Gain_P
							 ,CASE WHEN 1+(CONVERT(DECIMAL(10,2),Gain)/100)<=0 THEN 0.00001 ELSE 1+(CONVERT(DECIMAL(10,2),Gain)/100) END Gain_New
					   FROM BI_DB_dbo.BI_DB_PI_Gain
					   WHERE TimeFarme='M' 
							AND [Year]*100+[Month] BETWEEN YEAR(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -36,GETDATE())), 0))*100+
														   MONTH(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -36,GETDATE())), 0)) 
														   AND
														   YEAR(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -1,GETDATE())), 0))*100+
														   MONTH(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -1,GETDATE())), 0))
					 )Gain_36m
			
				GROUP BY RealCID
								) AS Gain_36M
											) AS Gain_36M
	ON Gain_12M.RealCID=Gain_36M.RealCID
JOIN (
		SELECT RealCID,
			   FORMAT(COALESCE(Gain_48M.Performance_48m, 1)-1,'P') AS Performance_48m
		FROM (
			   SELECT RealCID,
					  EXP(SUM(LOG(Gain_New))) AS Performance_48m 
			   FROM (
					  SELECT RealCID
							 ,[Year]*100+[Month] YearMonth
							 ,CONVERT(DECIMAL(10,2),Gain) Gain_P
							 ,CASE WHEN 1+(CONVERT(DECIMAL(10,2),Gain)/100)<=0 THEN 0.00001 ELSE 1+(CONVERT(DECIMAL(10,2),Gain)/100) END Gain_New
					   FROM BI_DB_dbo.BI_DB_PI_Gain
					   WHERE TimeFarme='M' 
							AND [Year]*100+[Month] BETWEEN YEAR(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -48,GETDATE())), 0))*100+
														   MONTH(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -48,GETDATE())), 0)) 
														   AND
														   YEAR(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -1,GETDATE())), 0))*100+
														   MONTH(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -1,GETDATE())), 0))
					 )Gain_48m
			
				GROUP BY RealCID
								) AS Gain_48M
											) AS Gain_48M
	ON Gain_12M.RealCID=Gain_48M.RealCID
JOIN (
		SELECT RealCID,
			   FORMAT(COALESCE(Gain_60M.Performance_60m, 1)-1,'P') AS Performance_60m
		FROM (
			   SELECT RealCID,
					  EXP(SUM(LOG(Gain_New))) AS Performance_60m 
			   FROM (
					  SELECT RealCID
							 ,[Year]*100+[Month] YearMonth
							 ,CONVERT(DECIMAL(10,2),Gain) Gain_P
							 ,CASE WHEN 1+(CONVERT(DECIMAL(10,2),Gain)/100)<=0 THEN 0.00001 ELSE 1+(CONVERT(DECIMAL(10,2),Gain)/100) END Gain_New
					   FROM BI_DB_dbo.BI_DB_PI_Gain
					   WHERE TimeFarme='M' 
							AND [Year]*100+[Month] BETWEEN YEAR(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -60,GETDATE())), 0))*100+
														   MONTH(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -60,GETDATE())), 0)) 
														   AND
														   YEAR(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -1,GETDATE())), 0))*100+
														   MONTH(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -1,GETDATE())), 0))
					 )Gain_60m
			
				GROUP BY RealCID
								) AS Gain_60M
											) AS Gain_60M
	ON Gain_12M.RealCID=Gain_60M.RealCID