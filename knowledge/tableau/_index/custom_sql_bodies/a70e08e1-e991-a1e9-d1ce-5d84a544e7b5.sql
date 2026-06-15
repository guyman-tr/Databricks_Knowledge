SELECT i.[Date]
      ,i.[DateID]
      ,i.[AccountManagerID]
      ,i.[CountryID]
      ,i.[RegulationID]
      ,i.[ActionType]
      ,i.[InstrumentType]
      ,i.[AssetType]
      ,i.[Customers]
      ,i.[Amount]
      ,i.[AUM_AUA]
      ,CASE WHEN UPPER(ISNULL(syn.[manager_type],'NULL')) = 'NULL' then 'Others' ELSE syn.[manager_type] END [manager_type]
  FROM [BI_DB].[dbo].[BI_DB_Investors_Unclustered] i
  LEFT JOIN (
  SELECT [manager_id]
       ,MAX(full_name)full_name
	   ,MAX(manager_type)manager_type
FROM [BI_DB].[dbo].[BI_DB_AccountManagers_List] syn WITH (NOLOCK)
GROUP BY [manager_id]
  )syn
  ON i.[AccountManagerID] = syn.[manager_id]
  AND full_name ! = 'Katie Barry'
where DateID >=20220101
and DateID <20230101