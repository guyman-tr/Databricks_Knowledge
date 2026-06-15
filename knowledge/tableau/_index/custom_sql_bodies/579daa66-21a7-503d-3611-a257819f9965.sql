SELECT bdfa.*
       ,DATEDIFF(dd,bdfa.FirstActionDate,bdfa.SecondActionDate) AS FirstToSecondDays
	   ,DATEDIFF(dd,bdfa.SecondActionDate,bdfa.ThirdActionDate) AS SecondToThirdDays
	   ,DATEDIFF(dd,bdfa.ThirdActionDate,bdfa.FourthActionDate) AS ThirdToFourthDays
	   ,DATEDIFF(dd,bdfa.FourthActionDate,bdfa.FifthActionDate) AS FourthToFifthDays
	   ,CASE WHEN bdfa.FirstAction IS NOT NULL THEN 1 ELSE 0 END AS Has_First_Action
	   ,CASE WHEN bdfa.SecondAction IS NOT NULL THEN 1 ELSE 0 END AS Has_Second_Action
	   ,CASE WHEN bdfa.ThirdAction IS NOT NULL THEN 1 ELSE 0 END AS Has_Third_Action
	   ,CASE WHEN bdfa.FourthAction IS NOT NULL THEN 1 ELSE 0 END AS Has_Fourth_Action
	   ,CASE WHEN bdfa.FifthAction IS NOT NULL THEN 1 ELSE 0 END AS Has_Fifth_Action
	   ,DATEDIFF(dd,bdfa.FirstActionDate,bdfa.ThirdActionDate) AS FirstToThirdDays
	   ,DATEDIFF(dd,bdfa.FirstActionDate,bdfa.FourthActionDate) AS FirstToFourthDays
	   ,DATEDIFF(dd,bdfa.FirstActionDate,bdfa.FifthActionDate) AS FirstToFifthDays
	   ,CASE WHEN DATEDIFF(dd,bdfa.FirstDepositDate,GETDATE()) <= 7 THEN '0-7'
	         WHEN DATEDIFF(dd,bdfa.FirstDepositDate,GETDATE()) <= 30 THEN '8-30'
			 WHEN DATEDIFF(dd,bdfa.FirstDepositDate,GETDATE()) <= 90 THEN '31-90'
			 WHEN DATEDIFF(dd,bdfa.FirstDepositDate,GETDATE()) <= 180 THEN '91-180'
			 WHEN DATEDIFF(dd,bdfa.FirstDepositDate,GETDATE()) <= 360 THEN '181-360'
		ELSE '360+' END
	   AS Seniority_Days
FROM BI_DB_dbo.BI_DB_First5Actions bdfa
WHERE bdfa.FirstDepositDate>='20230101' --AND bdfa.FirstDepositDate<'20230901'