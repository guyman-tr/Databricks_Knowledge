SELECT [BI_DB_SF_Cases_Panel].[AccountManagerID_AtOpen] AS [AccountManagerID_AtOpen],
  [BI_DB_SF_Cases_Panel].[AccountManagerID_Last] AS [AccountManagerID_Last],
  [BI_DB_SF_Cases_Panel].[ActionType_AtOpen] AS [ActionType_AtOpen],
  [BI_DB_SF_Cases_Panel].[ActionType_Last] AS [ActionType_Last],
  [BI_DB_SF_Cases_Panel].[ActiveAgentID_Atopen] AS [ActiveAgentID_Atopen],
  [BI_DB_SF_Cases_Panel].[ActiveAgentID_Last] AS [ActiveAgentID_Last],
  [BI_DB_SF_Cases_Panel].[CID_Last] AS [CID_Last],
  [Custom SQL Query].[CaseID] AS [CaseID],
  [Users].[CaseNumber] AS [CaseNumber (Custom SQL Query1)],
  [BI_DB_SF_Cases_Panel].[CaseNumber] AS [CaseNumber],
  [Users].[CaseOwner] AS [CaseOwner],
  [BI_DB_SF_Cases_Panel].[CloseDateTime] AS [CloseDateTime],
  [BI_DB_SF_Cases_Panel].[ClubTier_AtOpen] AS [ClubTier_AtOpen],
  [BI_DB_SF_Cases_Panel].[ClubTier_Last] AS [ClubTier_Last],
  [BI_DB_SF_Cases_Panel].[Country_AtOpen] AS [Country_AtOpen],
  [BI_DB_SF_Cases_Panel].[Country_Last] AS [Country_Last],
  [BI_DB_SF_Cases_Panel].[CreatedDate] AS [CreatedDate],
  [BI_DB_SF_Cases_Panel].[DaysToReplyEmail] AS [DaysToReplyEmail],
  [Users].[Department] AS [Department],
  [BI_DB_SF_Cases_Panel].[DepositorType_AtOpen] AS [DepositorType_AtOpen],
  [BI_DB_SF_Cases_Panel].[DepositorType_Last] AS [DepositorType_Last],
  [Custom SQL Query].[EventType_Internal] AS [EventType_Internal],
  [Custom SQL Query].[EventType_Outbound] AS [EventType_Outbound],
  csat.cSATFirst AS [FirstCSAT],
  [BI_DB_SF_Cases_Panel].[FirstResponse] AS [FirstResponse],
  [BI_DB_SF_Cases_Panel].[HandlingDays] AS [HandlingDays],
  [BI_DB_SF_Cases_Panel].[HandlingDayseToro] AS [HandlingDayseToro],
  [BI_DB_SF_Cases_Panel].[HistoryID_AtOpen] AS [HistoryID_AtOpen],
  [BI_DB_SF_Cases_Panel].[HistoryID_Last] AS [HistoryID_Last],
  [BI_DB_SF_Cases_Panel].[IsCHBCase] AS [IsCHBCase],
  [BI_DB_SF_Cases_Panel].[IsCOCall] AS [IsCOCall],
  [BI_DB_SF_Cases_Panel].[IsCOCase] AS [IsCOCase],
  [BI_DB_SF_Cases_Panel].[IsComplaint] AS [IsComplaint],
  [BI_DB_SF_Cases_Panel].[IsGoodwill] AS [IsGoodwill],
  [BI_DB_SF_Cases_Panel].[IsInternal] AS [IsInternal],
  [BI_DB_SF_Cases_Panel].[IsKYcMonitoring] AS [IsKYcMonitoring],
  [BI_DB_SF_Cases_Panel].[IsNormal] AS [IsNormal],
  [BI_DB_SF_Cases_Panel].[IsOfficial] AS [IsOfficial],
  [BI_DB_SF_Cases_Panel].[IsOneTouch] AS [IsOneTouch],
  [BI_DB_SF_Cases_Panel].[IsPPReport] AS [IsPPReport],
  [BI_DB_SF_Cases_Panel].[IsPhase2] AS [IsPhase2],
  [BI_DB_SF_Cases_Panel].[IsPhase3] AS [IsPhase3],
  [BI_DB_SF_Cases_Panel].[IsReopened] AS [IsReopened],
  [BI_DB_SF_Cases_Panel].[IsRisk] AS [IsRisk],
  [BI_DB_SF_Cases_Panel].[IsSocial] AS [IsSocial],
  [BI_DB_SF_Cases_Panel].[IsSpam] AS [IsSpam],
  [BI_DB_SF_Cases_Panel].[IsSupervisorCall] AS [IsSupervisorCall],
  [BI_DB_SF_Cases_Panel].[IsT3] AS [IsT3],
  [BI_DB_SF_Cases_Panel].[IsTechnicalRefund] AS [IsTechnicalRefund],
  [BI_DB_SF_Cases_Panel].[IsTechnicalTeam] AS [IsTechnicalTeam],
  [BI_DB_SF_Cases_Panel].[IsTmail] AS [IsTmail],
  [BI_DB_SF_Cases_Panel].[IsVisitor_Atopen] AS [IsVisitor_Atopen],
  [BI_DB_SF_Cases_Panel].[IsVisitor_Last] AS [IsVisitor_Last],
  csat.cSATLast AS [LastCSAT],
  [BI_DB_SF_Cases_Panel].[LastStatusDate] AS [LastStatusDate],
  [Users].[Name] AS [Name],
  [BI_DB_SF_Cases_Panel].[NumberIncomingMessages] AS [NumberIncomingMessages],
  [BI_DB_SF_Cases_Panel].[NumberOfTocuhes] AS [NumberOfTocuhes],
  [BI_DB_SF_Cases_Panel].[NumberOutgoingMessages] AS [NumberOutgoingMessages],
  [BI_DB_SF_Cases_Panel].[Owner_Atopen] AS [Owner_Atopen],
  [BI_DB_SF_Cases_Panel].[Owner_Last] AS [Owner_Last],
  [BI_DB_SF_Cases_Panel].[Phase_AtOpen] AS [Phase_AtOpen],
  [BI_DB_SF_Cases_Panel].[Phase_Last] AS [Phase_Last],
  [BI_DB_SF_Cases_Panel].[PlayerStatus_AtOpen] AS [PlayerStatus_AtOpen],
  [BI_DB_SF_Cases_Panel].[PlayerStatus_Last] AS [PlayerStatus_Last],
  [BI_DB_SF_Cases_Panel].[Priority_AtOpen] AS [Priority_AtOpen],
  [BI_DB_SF_Cases_Panel].[Priority_Last] AS [Priority_Last],
  [BI_DB_SF_Cases_Panel].[Product_AtOpen] AS [Product_AtOpen],
  [BI_DB_SF_Cases_Panel].[Product_Last] AS [Product_Last],
  [BI_DB_SF_Cases_Panel].[Regulation_AtOpen] AS [Regulation_AtOpen],
  [BI_DB_SF_Cases_Panel].[Regulation_Last] AS [Regulation_Last],
  [BI_DB_SF_Cases_Panel].[Role_AtOpen] AS [Role_AtOpen],
  [BI_DB_SF_Cases_Panel].[Role_Last] AS [Role_Last],
  [BI_DB_SF_Cases_Panel].[ServiceDesk_AtOpen] AS [ServiceDesk_AtOpen],
  [BI_DB_SF_Cases_Panel].[ServiceDesk_Last] AS [ServiceDesk_Last],
  [BI_DB_SF_Cases_Panel].[ServiceLanguage_AtOpen] AS [ServiceLanguage_AtOpen],
  [BI_DB_SF_Cases_Panel].[ServiceLanguage_Last] AS [ServiceLanguage_Last],
  [BI_DB_SF_Cases_Panel].[Source_AtOpen] AS [Source_AtOpen],
  [BI_DB_SF_Cases_Panel].[Source_Last] AS [Source_Last],
  [BI_DB_SF_Cases_Panel].[SubRole_AtOpen] AS [SubRole_AtOpen],
  [BI_DB_SF_Cases_Panel].[SubRole_Last] AS [SubRole_Last],
  [BI_DB_SF_Cases_Panel].[SubType2_AtOpen] AS [SubType2_AtOpen],
  [BI_DB_SF_Cases_Panel].[SubType2_Last] AS [SubType2_Last],
  [BI_DB_SF_Cases_Panel].[SubType_AtOpen] AS [SubType_AtOpen],
  [BI_DB_SF_Cases_Panel].[SubType_Last] AS [SubType_Last],
  [Users].[Subrole-User] AS [Subrole-User],
  [Users].[Team] AS [Team],
  [BI_DB_SF_Cases_Panel].[TicketID] AS [TicketID],
  [BI_DB_SF_Cases_Panel].[TicketStatus] AS [TicketStatus],
  [Users].[Title] AS [Title],
  [BI_DB_SF_Cases_Panel].[TotalTimeSpent] AS [TotalTimeSpent],
  [BI_DB_SF_Cases_Panel].[Type_AtOpen] AS [Type_AtOpen],
  [BI_DB_SF_Cases_Panel].[Type_Last] AS [Type_Last],
  [BI_DB_SF_Cases_Panel].[UpdateDate] AS [UpdateDate],
  [BI_DB_SF_Cases_Panel].[VerificationLevelID_AtOpen] AS [VerificationLevelID_AtOpen],
  [BI_DB_SF_Cases_Panel].[VerificationLevelID_Last] AS [VerificationLevelID_Last],
    dc.MarketingRegionManualName [Mkt_Region_AtOpen],
		dc1.MarketingRegionManualName [Mkt_Region_AtClose]
FROM [dbo].[BI_DB_SF_Cases_Panel] [BI_DB_SF_Cases_Panel]
JOIN DWH..Dim_Country dc ON [BI_DB_SF_Cases_Panel].Country_AtOpen = dc.Name
JOIN DWH..Dim_Country dc1 ON [BI_DB_SF_Cases_Panel].Country_Last = dc1.Name
left join [BI_DB].[dbo].[BI_DB_SF_M_cSAT]  csat on csat.CaseNumber=[BI_DB_SF_Cases_Panel].CaseNumber
  LEFT JOIN (
  SELECT bdsce.CaseID
  	  ,SUM(CASE WHEN bdsce.EventType = 'Outbound Email Message' THEN 1 ELSE 0   END) AS EventType_Outbound
  	  ,SUM(CASE WHEN bdsce.EventType = 'Internal Case Comment' THEN 1 ELSE 0   END) AS EventType_Internal  	
  FROM BI_DB.dbo.BI_DB_SF_Case_Event bdsce
  GROUP BY  bdsce.CaseID
) [Custom SQL Query] ON ([BI_DB_SF_Cases_Panel].[TicketID] = [Custom SQL Query].[CaseID])
  LEFT JOIN (
  SELECT bdscp.CaseNumber, 
  bdsmu.Name,
  bdsmu.Team, 
  bdsmu.Department, 
  bdsmu.Title, 
  bdsmu.SubRole as [Subrole-User],
  ISNULL(bdsmu.Name,'Queue') AS CaseOwner
  FROM BI_DB.dbo.BI_DB_SF_Cases_Panel bdscp
  LEFT JOIN BI_DB.dbo.BI_DB_SF_M_Users bdsmu ON bdsmu.Id = bdscp.Owner_Last AND bdsmu.ToDate = '9999-12-31'
) [Users] ON ([BI_DB_SF_Cases_Panel].[CaseNumber] = [Users].[CaseNumber])