SELECT CASE WHEN csc.Event_Date_Time__c >= DATEFROMPARTS(YEAR(csc.Event_Date_Time__c),3,27) AND csc.Event_Date_Time__c < DATEFROMPARTS(YEAR(csc.Event_Date_Time__c),9,27) 
		THEN DATEADD(ms,10800000,csc.Event_Date_Time__c) ELSE DATEADD(ms,7200000,csc.Event_Date_Time__c) END  EventDate
   ,csc.FullName FullName
   ,csc.CaseNumber CaseNumber
   ,sfu.Manager Manager
   ,DATEPART(HOUR, CASE WHEN csc.Event_Date_Time__c >= DATEFROMPARTS(YEAR(csc.Event_Date_Time__c),3,27) AND csc.Event_Date_Time__c < DATEFROMPARTS(YEAR(csc.Event_Date_Time__c),9,27) 
		THEN DATEADD(ms,10800000,csc.Event_Date_Time__c) ELSE DATEADD(ms,7200000,csc.Event_Date_Time__c) END )[HOUR]
   ,cp.TicketID
   ,cp.SubType_Last SubType
   ,cp.SubType2_Last SubType2
   ,csc.EventType EvenType
   ,cp.Source_Last [Source]
   ,COALESCE(sfu1.FullName,sfg.Name) Owner
FROM [BI_DB].[dbo].[BI_DB_SF_CS_Cases] csc
LEFT JOIN BI_DB.dbo.BI_DB_SF_Cases_Panel cp
	ON csc.CaseNumber = cp.CaseNumber
LEFT JOIN BI_DB.dbo.BI_DB_SF_Users sfu WITH (NOLOCK)
	ON Agent = sfu.Id
LEFT JOIN BI_DB.dbo.BI_DB_SF_Users sfu1 WITH (NOLOCK)
ON cp.Owner_Last = sfu1.Id
LEFT JOIN [SalesForce_DB_Prod].[dbo].[SalesForce_Group] sfg WITH (NOLOCK)
ON sfg.Id = cp.Owner_Last
WHERE ((EventType IN ('Internal Case Comment', 'Outbound Email Message') AND cp.Source_AtOpen != 'Chat')
or cp.Source_AtOpen = 'Chat')