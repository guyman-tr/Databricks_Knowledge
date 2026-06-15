SELECT [CountryID]
      ,[Name]
      ,[Region] RegionDWH
      ,[Desk]
      ,CASE 
       --WHEN Region IN ('ROE','Eastern Europe','North Europe') THEN 'Europe' 
       WHEN Region IN ('Africa','ROW','Israel','Russian') THEN 'ROW' 
       WHEN Region IN ('Arabic GCC','Arabic Other') THEN 'Arabic GCC & Other'
       WHEN Region IN ('China','Other Asia') THEN 'China & Other Asia'
       WHEN Region IN ('Spain') THEN 'Spanish' 
       WHEN Region IN ('South & Central America') THEN 'LATAM' ELSE Region END as Region
  FROM [DWH].[dbo].[Dim_Country]