SELECT ed.[RealCID]
	  ,CASE WHEN dc1.Region IN ('ROE','Eastern Europe','North Europe') THEN 'Europe' 
       WHEN dc1.Region IN ('Africa','ROW','Israel','Russian') THEN 'ROW' 
       WHEN dc1.Region IN ('Arabic GCC','Arabic Other') THEN 'Arabic GCC & Other'
       WHEN dc1.Region IN ('China','Other Asia') THEN 'China & Other Asia'
       WHEN dc1.Region IN ('Spain') THEN 'Spanish' 
       WHEN dc1.Region IN ('South & Central America') THEN 'LATAM' ELSE dc1.Region END as Region
	  ,dl.Name Language
  FROM [BI_DB].[dbo].[BI_DB_Expected_ClubLevel_Downgrade] ed
  INNER JOIN [DWH].[dbo].[Dim_Customer] dc
  ON ed.RealCID = dc.RealCID
  INNER JOIN [DWH].[dbo].[Dim_Country] dc1
  ON dc.CountryID = dc1.CountryID
  INNER JOIN DWH.dbo.Dim_Language dl
  ON dc.LanguageID = dl.LanguageID