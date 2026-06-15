SELECT sfc.[DateID] AS [DateID],
  sfc.[Date] AS [Date],
--  q1.MaxMonth,
--  IsSolved,
  sfc.[CID] AS [CID],
  sfc.[CreatedDate] AS [CreatedDate],
  sfc.[TicketID] AS [TicketID],
  sfc.[LogID] AS [LogID],
  sfc.[TicketStatus] AS [TicketStatus],
  sfc.[RegulationAtOpen] AS [RegulationAtOpen],
  sfc.[ClubTierAtOpen] AS [ClubTierAtOpen],
  sfc.[Desk] AS [Desk],
  sfc.[Source] AS [Source],
  sfc.[Priority] AS [Priority],
  sfc.[Product] AS [Product],
  sfc.[SubType] AS [SubType],
  sfc.[SubType2] AS [SubType2],
  sfc.[ActionType] AS [ActionType],
  sfc.[IsActiveCustomer] AS [IsActiveCustomer],
  sfc.[UpdateDate] AS [UpdateDate],
  sfc.[Language] AS [Language],
  sfc.[Type] AS [Type],
  sfc.[IsAutoSolved] AS [IsAutoSolved],
  sfc.[DaysFromFTD] AS [DaysFromFTD],
  sfc.[IsDepositor] AS [IsDepositor],
  sfc.[AssignedTo] AS [AssignedTo],
  sfc.[HistoryID] AS [HistoryID],
  sfc.[LastCsat] AS [LastCsat],
  sfc.[FirstCsat] AS [FirstCsat],
  sfc.[Phase] AS [Phase],
  sfc.[Sub_Role__c] AS [Sub_Role__c],
  sfc.[Team__c] AS [Team__c],
  sfc.[UserRoleId] AS [UserRoleId],
  sfc.[Chat_Score__c] AS [Chat_Score__c],
  sfc.[CreatedById] AS [CreatedById],
  sfc.[DeveloperName] AS [DeveloperName],
  dpl.Name TierAtCSAT,
  sfc.MinCreatedDateCSAT,
  sfc.MaxCreatedDateCSAT,
dc.Name Country
FROM [dbo].[BI_DB_SF_Cases] sfc
LEFT JOIN DWH..Fact_SnapshotCustomer sc
on sfc.CID = sc.RealCID
INNER JOIN DWH..Dim_Range dr
on sc.DateRangeID = dr.DateRangeID
AND CONVERT(CHAR(8),CAST(sfc.MaxCreatedDateCSAT AS DATE),112) >= FromDateID
AND  CONVERT(CHAR(8),CAST(sfc.MaxCreatedDateCSAT AS DATE),112) <= ToDateID
LEFT JOIN DWH..Dim_PlayerLevel dpl
ON sc.PlayerLevelID = dpl.PlayerLevelID
JOIN DWH..Dim_Country dc
ON sc.CountryID = dc.CountryID
WHERE Source <> 'Email'