SELECT [BI_DB_Investors].[Date] AS [Date],
  [BI_DB_Investors].[DateID] AS [DateID],
  [BI_DB_Investors].[AccountManagerID] AS [AccountManagerID],
  [BI_DB_Investors].[CountryID] AS [CountryID],
  [BI_DB_Investors].[RegulationID] AS [RegulationID],
  [BI_DB_Investors].[ActionType] AS [ActionType],
  [BI_DB_Investors].[InstrumentType] AS [InstrumentType],
  [BI_DB_Investors].[AssetType] AS [AssetType],
  [BI_DB_Investors].[Customers] AS [Customers],
  [BI_DB_Investors].[Amount] AS [Amount],
  [BI_DB_Investors].[AUM_AUA] AS [AUM_AUA],
  [BI_DB_Investors].[UpdateDate] AS [UpdateDate],
  [BI_DB_Investors].[ClusterSF] AS [ClusterSF],
  [desk],
CASE WHEN UPPER(ISNULL(syn.[manager_type],'NULL')) = 'NULL' then 'Others' ELSE syn.[manager_type] END [manager_type]
FROM [dbo].[BI_DB_Investors] [BI_DB_Investors]
 LEFT JOIN (
  SELECT [manager_id]
       ,[desk]
       ,MAX(full_name)full_name
	   ,MAX(manager_type)manager_type
FROM [ThirdParty_Fivetran].[Fivetran].[gsheets].[customer_managers] syn WITH (NOLOCK)
GROUP BY [manager_id],[desk]
  )syn
  ON [BI_DB_Investors].[AccountManagerID] = syn.[manager_id]
where DateID >=20210801
AND CASE WHEN UPPER(ISNULL(syn.[manager_type],'NULL')) = 'NULL' then 'Others' ELSE syn.[manager_type] END <> 'Others'