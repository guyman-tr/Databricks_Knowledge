SELECT dd.FullDate AS [Date]
      ,[DateID]
      ,[AccountManagerID]
      ,[CountryID]
      ,[RegulationID]
      ,[ActionType]
      ,[InstrumentType]
      ,[AssetType]
      ,[Customers]
      ,[Amount]
      ,[AUM_AUA]
      ,CASE WHEN  UPPER(manager_type) = 'NULL' THEN 'General' ELSE manager_type END manager_type
      ,[desk]
      ,[is_active]
FROM [BI_DB].[dbo].[BI_DB_Investors] WITH (NOLOCK)
INNER JOIN [BI_DB].[dbo].[Syn_gsheets.customer_managers] WITH (NOLOCK)
ON [AccountManagerID] = [manager_id]
inner join [DWH].[dbo].[Dim_Date] dd WITH (NOLOCK)
ON [DateID] = DateKey
WHERE [manager_type] = 'Investor AM'
AND DateID >= convert(char(8),DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE()-1)-3,0),112)