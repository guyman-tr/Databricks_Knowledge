SELECT atufb.AM_Assign 
                ,atufb.Desk 
		,atufb.CID
		, mp.EOM_Club 
                ,CASE WHEN mp.Region LIKE '%Arabic%' THEN 'Arabic' 
		WHEN mp.Region LIKE '%East%' OR mp.Region LIKE '%ROW%' THEN 'ROW'
		ELSE mp.Region END Region
		,MAX(CASE WHEN bduts.ActionName IN ('Phone_Call_Succeed__c','Completed_Contact_Email__c') THEN 1 ELSE 0 END) Contacted
		,MIN(CASE WHEN bduts.ActionName  IN ('Outbound_Email__c','Contacted__c') THEN 1 ELSE 0 END) AttemptedContacted
		,MIN(bdcdpc.TierChangeDate) Change
		,MIN(CASE WHEN bduts.ActionName IN ('Phone_Call_Succeed__c','Completed_Contact_Email__c') THEN bduts.CreatedDate_SF ELSE NULL END) SFDate
		,atufb.Date
		,mp.UpdateDate
                ,bdsmu.Name
        ,bdsmu.Position
        ,bdsmu.IsActive
        ,bdsmu.Desk DeskFromAM
        ,bdsmu.Team
FROM (SELECT bdsmu.Name
        ,bdsmu.Position
        ,bdsmu.IsActive
        ,bdsmu.Desk
        ,bdsmu.Team
  FROM BI_DB.dbo.BI_DB_SF_M_Users bdsmu
  WHERE bdsmu.ToDate = '9999-12-31'
  UNION ALL 
    SELECT TOP 1 'Dummy' Name
        ,'Dummy' Position
        ,'1' IsActive
        ,'Dummy' Desk
        ,'Dummy' Team
  FROM BI_DB.dbo.BI_DB_SF_M_Users bdsmu
  WHERE bdsmu.ToDate = '9999-12-31') bdsmu
LEFT JOIN BI_DB.dbo.BI_DB_AB_Test_Upgrade_from_Bronze atufb
ON bdsmu.Name = atufb.AM_Assign
LEFT JOIN BI_DB.dbo.BI_DB_CID_MonthlyPanel_FullData mp
ON mp.CID = atufb.CID
AND mp.ActiveDate = atufb.Date
LEFT JOIN BI_DB_UsageTracking_SF bduts
ON mp.CID = bduts.CID
AND bduts.CreatedDate_SF>=DATEADD(dd,-30,atufb.Date)
AND bduts.CreatedDate_SF<=EOMONTH(atufb.Date)
LEFT JOIN BI_DB_CID_DailyPanel_Club bdcdpc
ON bdcdpc.Date >=atufb.Date
AND bdcdpc.Date<=EOMONTH(atufb.Date)
AND mp.CID = bdcdpc.CID
AND bdcdpc.IsUpgrade = 1
AND mp.CID IS NOT NULL
GROUP BY atufb.AM_Assign 
                ,atufb.Desk
		,atufb.CID
		, mp.EOM_Club 
		,atufb.Date
		,mp.UpdateDate
                ,CASE WHEN mp.Region LIKE '%Arabic%' THEN 'Arabic' 
		WHEN mp.Region LIKE '%East%' OR mp.Region LIKE '%ROW%' THEN 'ROW'
		ELSE mp.Region END
                ,bdsmu.Name
                        ,bdsmu.Position
                        ,bdsmu.IsActive
                        ,bdsmu.Desk
                        ,bdsmu.Team