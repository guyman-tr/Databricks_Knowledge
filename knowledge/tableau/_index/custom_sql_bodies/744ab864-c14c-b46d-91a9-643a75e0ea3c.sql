SELECT [BI_DB_SF_HistoryCases].[Date] AS [Date],
  [BI_DB_SF_HistoryCases].[DateID] AS [DateID],
  [BI_DB_SF_HistoryCases].[CreatedDate] AS [CreatedDate],
  [BI_DB_SF_HistoryCases].[Occurred] AS [Occurred],
  [BI_DB_SF_HistoryCases].[TicketStatus] AS [TicketStatus],
  [BI_DB_SF_HistoryCases].[StatusAfter30Days] AS [StatusAfter30Days],
  [BI_DB_SF_HistoryCases].[TicketID] AS [TicketID],
  [BI_DB_SF_HistoryCases].[CID] AS [CID],
  [BI_DB_SF_HistoryCases].[Type] AS [Type],
  [BI_DB_SF_HistoryCases].[SubType] AS [SubType],
  [BI_DB_SF_HistoryCases].[RegistrationDate] AS [RegistrationDate],
  [BI_DB_SF_HistoryCases].[FTDDate] AS [FTDDate],
  [BI_DB_SF_HistoryCases].[AssetsValue] AS [AssetsValue],
  [BI_DB_SF_HistoryCases].[AssetsValueAfter30Days] AS [AssetsValueAfter30Days],
  [BI_DB_SF_HistoryCases].[AvgVolume] AS [AvgVolume],
  [BI_DB_SF_HistoryCases].[AvgVolumeAfter30Days] AS [AvgVolumeAfter30Days],
  [BI_DB_SF_HistoryCases].[Deposits30DBefore] AS [Deposits30DBefore],
  [BI_DB_SF_HistoryCases].[Withdrawal30DBefore] AS [Withdrawal30DBefore],
  [BI_DB_SF_HistoryCases].[Deposits30DAfter] AS [Deposits30DAfter],
  [BI_DB_SF_HistoryCases].[Withdrawal30DAfter] AS [Withdrawal30DAfter],
  [BI_DB_SF_HistoryCases].[Logins30DBefore] AS [Logins30DBefore],
  [BI_DB_SF_HistoryCases].[Logins30DAfter] AS [Logins30DAfter],
  [BI_DB_SF_HistoryCases].[Revenue] AS [Revenue],
  [BI_DB_SF_HistoryCases].[Revenue30DAfter] AS [Revenue30DAfter],
  [BI_DB_SF_HistoryCases].[UpdateDate] AS [UpdateDate],
  [BI_DB_SF_HistoryCases].[Source] AS [Source],
  [BI_DB_SF_HistoryCases].[AssetsValueAfter60Days] AS [AssetsValueAfter60Days],
  [BI_DB_SF_HistoryCases].[AssetsValueAfter90Days] AS [AssetsValueAfter90Days],
  [BI_DB_SF_HistoryCases].[AssetsValueAfter12Days] AS [AssetsValueAfter12Days],
  [BI_DB_SF_HistoryCases].[OpenTicketIND] AS [OpenTicketIND],
  [BI_DB_SF_HistoryCases].[DepositsAllMonth] AS [DepositsAllMonth],
  [BI_DB_SF_HistoryCases].[LoginsAllMonth] AS [LoginsAllMonth],
  [BI_DB_SF_HistoryCases].[RevenuesAllMonth] AS	[RevenuesAllMonth],
  [BI_DB_SF_HistoryCases].[WithdrawlAllMonth] AS [WithdrawlAllMonth],
  dpl.Name ClubTier,
  dc1.Region,
  [BI_DB_SF_HistoryCases].ActionType
 
FROM [dbo].[BI_DB_SF_HistoryCases] [BI_DB_SF_HistoryCases]
INNER JOIN [DWH].[dbo].[Dim_Customer] dc
ON dc.RealCID = [BI_DB_SF_HistoryCases].CID
INNER JOIN [DWH].[dbo].[Dim_PlayerLevel] dpl WITH (NOLOCK)
ON dc.PlayerLevelID = dpl.PlayerLevelID
LEFT JOIN [DWH].[dbo].[Dim_Country] dc1
ON dc.CountryID = dc1.CountryID
where DateID >= 20191201
and AssetsValue > 25