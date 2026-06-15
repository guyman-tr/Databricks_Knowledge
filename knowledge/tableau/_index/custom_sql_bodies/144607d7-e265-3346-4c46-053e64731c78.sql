SELECT a.*
      ,CASE WHEN b.CID IS NOT NULL THEN 1 ELSE 0 END AS Is_LTV_Valid
	  ,b.NewMarketingRegion AS LTV_Region
	  ,b.FirstFundedMonth AS LTV_FirstFundedMonth
	  ,b.ClusterDetail AS LTV_ClusterDetail
	  ,b.EquityTier AS LTV_EquityTier
      ,DATEDIFF(MONTH,a.FirstDepositDate,GETDATE()) AS Seniority
	  ,CASE WHEN YEAR(a.FirstDepositDate)= 2024 THEN '2024'
	        WHEN YEAR(a.FirstDepositDate)= 2023 THEN '2023'
	        WHEN YEAR(a.FirstDepositDate)= 2022 THEN '2022'
	        WHEN YEAR(a.FirstDepositDate)= 2021 THEN '2021'
	        WHEN YEAR(a.FirstDepositDate)= 2020 THEN '2020'
			WHEN YEAR(a.FirstDepositDate)= 2019 THEN '2019'
	   ELSE '<2019' END AS FTD_Year_Group
FROM [BI_DB_dbo].[BI_DB_New_Revenue_LTV1] a
LEFT JOIN BI_DB_dbo.BI_DB_LTV_BI_Actual b ON b.CID=a.CID