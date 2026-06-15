SELECT 1 IsCurrentYear
      ,i.[Date]
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
where DateID >=CONVERT(CHAR(8),DATEFROMPARTS(YEAR(GETDATE()),1,1),112)
union 
SELECT 0 IsCurrentYear
      ,i.[Date]
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
      ,' '[manager_type]
  FROM [BI_DB_dbo].[BI_DB_Investors_Unclustered] i
where DateID =CONVERT(CHAR(8),DATEADD(day,-1,DATEFROMPARTS(YEAR(GETDATE()),1,1)),112)