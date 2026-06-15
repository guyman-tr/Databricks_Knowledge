SELECT bdcc.[Event_Date_Time__c] AS [Event_Date_Time__c],
  CAST(bdcc.Event_Date_Time__c AS DATE) DATE,
  bdcc.[Agent] AS [Agent],
  bdcc.[FullName] AS [FullName],
  bdcc.[TicketID] AS [TicketID],
  bdcc.[EventType] AS [EventType],
  bdcc.[Old_Status__c] AS [Old_Status__c],
  bdcc.[New_Status__c] AS [New_Status__c],
  CASE WHEN bdcc.[Old_Status__c] = 'Solved' AND bdcc.[New_Status__c] <> 'Closed' THEN 1 END Reopen,
  LEAD(CASE WHEN bdcc.[Old_Status__c] = 'Solved' AND bdcc.[New_Status__c] <> 'Closed' THEN 1 END, 1) OVER (PARTITION BY bdcc.TicketID ORDER BY bdcc.Event_Date_Time__c) ReopenAgent,
  bdcc.[CaseNumber],
  bdcc.[FirstCsat],
  bdcc.[LastCsat],
  sfu.Reports_to__c,
  ReportsTo_BOB,
  sfu.Country,
  sfu1.Country TeamLeadCountry,
  sfu.IsActive,
  us.IsOutsourced,
  sfu.CreatedDate StartWorking,
  cp.TicketStatus,
  IsAutoSolved,
  sfce.Updated_by_automatic_process__c AS IsAutomaticProcess,
  IsReopened,
  IsPPReport,
  DATEDIFF(MINUTE,MIN(bdcc.Event_Date_Time__c) OVER (PARTITION BY bdcc.TicketID, bdcc.Agent,DATEPART(MONTH,bdcc.Event_Date_Time__c),DATEPART(DAY,bdcc.Event_Date_Time__c)),
  MAX(bdcc.Event_Date_Time__c) OVER (PARTITION BY bdcc.TicketID,bdcc.Agent,DATEPART(MONTH,bdcc.Event_Date_Time__c),DATEPART(DAY,bdcc.Event_Date_Time__c))) MinutesOnTicket,
  ROW_NUMBER()OVER(PARTITION BY bdcc.TicketID,bdcc.Agent ORDER BY bdcc.Event_Date_Time__c) rn,
  cp.Role_Last,
  CASE WHEN DATEPART(DAY,bdcc.Event_Date_Time__c) = DATEPART(DAY,bdcc.DateOfNextAction) then 1 ELSE 0 END IsSameDay
FROM [dbo].[BI_DB_SF_CS_Cases] bdcc
LEFT JOIN [SalesForce_DB_Prod].[dbo].[SalesForce_CaseEvents] sfce
ON bdcc.TicketID = sfce.Case__c
AND bdcc.Old_Status__c = sfce.Old_Status__c
AND bdcc.New_Status__c = sfce.New_Status__c
AND bdcc.Event_Date_Time__c = sfce.Event_Date_Time__c
LEFT JOIN [BI_DB].[dbo].[BI_DB_SF_Users] us 
ON bdcc.Agent = us.Id
LEFT JOIN [SalesForce_DB_Prod].[dbo].[SalesForce_User] sfu
ON bdcc.Agent = sfu.Id
AND sfu.Department IN ('CS','OPS')
LEFT JOIN [SalesForce_DB_Prod].[dbo].[SalesForce_User] sfu1
ON us.ReportsToID_BOB = sfu1.Id
LEFT JOIN BI_DB.dbo.BI_DB_SF_Cases_Panel cp
ON bdcc.TicketID = cp.TicketID
where bdcc.CreatedDate >= '20211001'