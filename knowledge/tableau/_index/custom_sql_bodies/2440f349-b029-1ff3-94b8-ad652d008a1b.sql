SELECT [Custom SQL Query].[AUM_AUA] AS [AUM_AUA],
  [Custom SQL Query].[AccountManagerID] AS [AccountManagerID],
  [Custom SQL Query].[ActionType] AS [ActionType],
  [Custom SQL Query].[Amount] AS [Amount],
  [Custom SQL Query].[AssetType] AS [AssetType],
  [Dim_Manager].[CalendlyID] AS [CalendlyID],
  [Dim_Regulation].[ClusterRegulationID] AS [ClusterRegulationID],
  [Custom SQL Query1].[CountryID] AS [CountryID (Custom SQL Query1)],
  [Custom SQL Query].[CountryID] AS [CountryID],
  [Custom SQL Query].[Customers] AS [Customers],
  [Dim_Manager].[DWHManagerID] AS [DWHManagerID],
  [Dim_Regulation].[DWHRegulationID] AS [DWHRegulationID],
  [Custom SQL Query].[DateID] AS [DateID],
  [Custom SQL Query].[Date] AS [Date],
  [Custom SQL Query1].[Desk] AS [Desk],
  [Dim_Manager].[FirstName] AS [FirstName],
  [Dim_Regulation].[ID] AS [ID],
  [Dim_Regulation].[InsertDate] AS [InsertDate (Dim_Regulation)],
  [Dim_Manager].[InsertDate] AS [InsertDate],
  [Custom SQL Query].[InstrumentType] AS [InstrumentType],
  [Dim_Manager].[IsActive] AS [IsActive],
  [Dim_Manager].[IsTeamLeader] AS [IsTeamLeader],
  [Dim_Manager].[LastName] AS [LastName],
  [Dim_Manager].[ManagerID] AS [ManagerID],
  [Dim_Regulation].[Name] AS [Name (Dim_Regulation)],
  [Custom SQL Query1].[Name] AS [Name],
  [Dim_Manager].[ParentUserGroup] AS [ParentUserGroup],
  [Custom SQL Query1].[RegionDWH] AS [RegionDWH],
  [Custom SQL Query1].[Region] AS [Region],
  [Custom SQL Query].[RegulationID] AS [RegulationID],
  [Dim_Manager].[SFManagerID] AS [SFManagerID],
  [Dim_Regulation].[StatusID] AS [StatusID (Dim_Regulation)],
  [Dim_Manager].[StatusID] AS [StatusID],
  [Dim_Manager].[UpdateDate] AS [UpdateDate (Dim_Manager)],
  [Dim_Regulation].[UpdateDate] AS [UpdateDate (Dim_Regulation)],
  [Custom SQL Query].[UpdateDate] AS [UpdateDate],
  [Dim_Manager].[UserGroup] AS [UserGroup],
  [Custom SQL Query].[manager_type] AS [manager_type]
FROM (
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
   where DateID >=20250101
  and DateID <20260101
) [Custom SQL Query]
  LEFT JOIN (
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
    FROM [DWH_dbo].[Dim_Country]
) [Custom SQL Query1] ON ([Custom SQL Query].[CountryID] = [Custom SQL Query1].[CountryID])
  LEFT JOIN [DWH_dbo].[Dim_Manager] [Dim_Manager] ON ([Custom SQL Query].[AccountManagerID] = [Dim_Manager].[ManagerID])
  LEFT JOIN [DWH_dbo].[Dim_Regulation] [Dim_Regulation] ON ([Custom SQL Query].[RegulationID] = [Dim_Regulation].[DWHRegulationID])