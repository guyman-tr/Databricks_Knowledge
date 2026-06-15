SELECT 
      i.[Date]
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
      ,i.UpdateDate
      ,' ' [manager_type]
  FROM [BI_DB_dbo].[BI_DB_Investors_Unclustered] i
 where DateID >=20240101
and DateID <20250101