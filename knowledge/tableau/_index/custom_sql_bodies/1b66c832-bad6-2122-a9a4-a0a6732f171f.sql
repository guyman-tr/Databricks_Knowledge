SELECT bdfa.CID
       ,YEAR(bdfa.FirstDepositDate)*100+MONTH(bdfa.FirstDepositDate) AS FTD_MONTH 
       --,YEAR(bdfa.FirstDepositDate)*100+DATEPART(QUARTER,bdfa.FirstDepositDate) AS FTD_Q
       --,YEAR(bdfa.FirstDepositDate) as Year_FTD
      ,YEAR(p.RegDate)*100+MONTH(p.RegDate) AS REG_MONTH 
      --,YEAR(p.RegDate) as Year_REG
      ,bdfa.Channel
      ,bdfa.SubChannel
      ,bdfa.NewMarketingRegion as Region
      ,bdfa.Country
      ,CASE WHEN YEAR(p.RegDate)= 2026 then '2026'
WHEN YEAR(p.RegDate)= 2025 then '2025'
	        WHEN YEAR(p.RegDate)= 2024 then '2024'
            WHEN YEAR(p.RegDate)= 2023 then '2023'
            WHEN YEAR(p.RegDate)= 2022 then '2022' 
            WHEN YEAR(p.RegDate)= 2021 then '2021' 
            WHEN YEAR(p.RegDate)= 2020 then '2020' 
            WHEN YEAR(p.RegDate)= 2019 then '2019'  
            WHEN YEAR(p.RegDate)= 2018 then '2018'  
            WHEN YEAR(p.RegDate)= 2017 then '2017'    
            ELSE
            'Before 2017' END AS RegYear
      --,dpl.Name Club
      --,CASE WHEN dpl.Name = 'Bronze' THEN 'No Club' ELSE 'Club' END AS Club_group
FROM [BI_DB_dbo].[BI_DB_First5Actions] bdfa
JOIN [DWH_dbo].[Dim_Customer] dc
ON bdfa.CID=dc.RealCID
JOIN [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData]  p
ON bdfa.CID = p.CID
WHERE bdfa.FirstDepositDate>='2024-01-01' --AND bdfa.FirstDepositDate<'2024-09-01'
and p.Seniority=0
and dc.IsValidCustomer=1
AND dc.RealCID NOT IN (
SELECT dc.RealCID  
FROM DWH_dbo.Dim_Customer AS dc
WHERE cast(dc.FirstDepositDate AS date) >= '2025-08-19' 
     AND cast(dc.FirstDepositDate AS date) <= '2025-08-21' 
     AND dc.FirstDepositAmount = 1)