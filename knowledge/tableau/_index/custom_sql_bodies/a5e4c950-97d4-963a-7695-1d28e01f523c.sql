SELECT [BI_DB_QualifiedLead].[CID] AS [CID],
  [BI_DB_QualifiedLead].[Registered] AS [Registered],
  [BI_DB_QualifiedLead].[FTDDate] AS [FTDDate],
  [BI_DB_QualifiedLead].[CountryID] AS [CountryID],
  [BI_DB_QualifiedLead].[AffID] AS [AffID],
  [BI_DB_QualifiedLead].[SubChannel] AS [SubChannel],
  [BI_DB_QualifiedLead].[Channel] AS [Channel],
  [BI_DB_QualifiedLead].[Country] AS [Country],
  [BI_DB_QualifiedLead].[Region] AS [Region],
  [BI_DB_QualifiedLead].[FunnelFromName] AS [FunnelFromName],
  [BI_DB_QualifiedLead].[NameDate] AS [NameDate],
  [BI_DB_QualifiedLead].[Verification1Date] AS [Verification1Date],
  [BI_DB_QualifiedLead].[Verification2Date] AS [Verification2Date],
  [BI_DB_QualifiedLead].[Verification3Date] AS [Verification3Date],
  [BI_DB_QualifiedLead].[ContactAttempt] AS [ContactAttempt],
  [BI_DB_QualifiedLead].[Contact] AS [Contact], c.Desk
FROM [dbo].[BI_DB_QualifiedLead] [BI_DB_QualifiedLead]
Left Join DWH.dbo.Dim_Country c
on [BI_DB_QualifiedLead].[CountryID] = c.[CountryID]