SELECT r.[ApexID] AS [ApexID],
  r.[ApexStatus] AS [ApexStatus],
  r.[ErrortDate] AS [ErrortDate],
  r.[GCID] AS [GCID],
  r.[IsDepositor] AS [IsDepositor],
  r.[Liabilities] AS [Liabilities],
  r.[PendingClosureStatusName] AS [PendingClosureStatusName],
  r.[PlayerStatus] AS [PlayerStatus],
  r.[RealCID] AS [RealCID],
  r.[RegulationID] AS [RegulationID],
  r.[TicketInd] AS [TicketInd],
  r.[UpdateDate] AS [UpdateDate],
  r.[ValidationError] AS [ValidationError],
dc.RegisteredReal,
sr.ReasonConstant,
ReasonDescription,
dc.VerificationLevelID
FROM [dbo].[BI_DB_H_US_Apex_Rejected_Accounts] r
join DWH.dbo.Dim_Customer dc on dc.RealCID=r.RealCID
left join [USABroker].[USABroker].Apex.SketchInvestigationDoNotAppealReason  sr on sr.ApexID  COLLATE Latin1_General_BIN =r.ApexID