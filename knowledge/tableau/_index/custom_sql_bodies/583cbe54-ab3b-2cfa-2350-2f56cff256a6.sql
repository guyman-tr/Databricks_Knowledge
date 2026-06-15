SELECT c.[Id]
		,c.[Name]
		,c.[Status]
		,c.[Registrant_count__c]
      ,c.[attended_count__c]
      ,c.[etc__c]
      ,c.[Attended_live_count__c]
      ,c.[Attended_archive_count__c]
		,CAST( c.[Webinar_End_Time__c] AS Date) endDate
	 ,CAST( c.[Webinar_Start_Time__c] AS Date) startDate
	  ,CAST( c.[Webinar_End_Time__c] AS TIME) endTime
	 ,CAST( c.[Webinar_Start_Time__c] AS TIME) startTime
	 ,c.[Webinar_Timezone__c]
	 ,w.[Archive_minutes__c]
	 ,w.[Email__c]
	 ,w.[Event_time__c]
      ,w.[First_Name__c]
      ,w.[Join_Time__c]
      ,w.[Last_Name__c]
      ,w.[Leave_Time__c]
      ,w.[Live_Minutes__c]
      ,w.[status__c] cidSTATUS
      ,dc.GCID
      ,dc.RealCID
	  FROM BI_DB_SF_STG_Campaign c
	   FULL OUTER join [BI_DB].[dbo].[BI_DB_SF_STG_Webcast] w
           on c.Id=w.campaign_id__c
           LEFT join [DWH].[dbo].[Dim_Customer] dc
           on dc.Email=w.Email__c
	  WHERE c.Type='Webinar'