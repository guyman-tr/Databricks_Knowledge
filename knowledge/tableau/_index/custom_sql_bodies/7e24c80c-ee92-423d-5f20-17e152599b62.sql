SELECT ad.ApexID
      --,ad.GCID
	  --,ud.CID
      --,ad.StatusID
      ,st.Name AS 'ApexStatus'
      ,ud.ApprovedByDate AS 'ApexApprovedDate'
FROM BI_DB_dbo.External_USABroker_Apex_ApexData ad 
LEFT JOIN BI_DB_dbo.External_USABroker_Dictionary_ApexStatus st  ON ad.StatusID = st.StatusID
LEFT JOIN BI_DB_dbo.External_USABroker_Apex_UserData ud ON ad.GCID = ud.GCID