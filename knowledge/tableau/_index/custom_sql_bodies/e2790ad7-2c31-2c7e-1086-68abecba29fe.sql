SELECT CID
       ,Cluster_UK_Test,Region
	   ,ClubUK_Test
	   ,ISNULL(Equity_First_M_Test,0)Equity_First_M_Test
	   ,ISNULL(FTDA_First_M_Test,0)FTDA_First_M_Test
	   ,ISNULL(Dep_Amount_First_M_Test,0)Dep_Amount_First_M_Test
	   ,ISNULL(Dep_Count_First_M_Test,0)Dep_Count_First_M_Test
	   ,CASE WHEN ISNULL(Equity_First_M_Test,0) < 50 THEN '<50'
	         WHEN ISNULL(Equity_First_M_Test,0) <= 100 THEN '51-100'
	         WHEN ISNULL(Equity_First_M_Test,0) <= 500 THEN '101-500'
			 ELSE '500+' END AS Equity_First_M_Test_Tier  
	   ,CASE WHEN ISNULL(Dep_Count_First_M_Test,0) = 0 THEN '0'
	         WHEN ISNULL(Dep_Count_First_M_Test,0) <= 1 THEN '1'
	         WHEN ISNULL(Dep_Count_First_M_Test,0) <= 3 THEN '2-3'
			 ELSE '3+' END AS Dep_Count_First_M_Test_Tier  
	   ,CASE WHEN ISNULL(Dep_Amount_First_M_Test,0) <=250 THEN '<250$'
	         WHEN ISNULL(Dep_Amount_First_M_Test,0) <=1000 THEN '251$-1K$'
			 WHEN ISNULL(Dep_Amount_First_M_Test,0) <=5000 THEN '1K$-5K$'
			 ELSE '5K$+' END AS Dep_Amount_First_M_Test_Tier  
		,CASE WHEN Dep_Amount_First_M_Test >=100000 THEN 1 ELSE 0 END Is_Dep_Amount_Extreme
	   ,ConversionFee
	   ,TotalFullCommission
	   ,RolloverFee
	   ,FirstDepositDate
FROM [BI_DB_dbo].[BI_DB_New_Revenue_LTV1]
WHERE Region='UK' AND YEAR(FirstDepositDate)=2022