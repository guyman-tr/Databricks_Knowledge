SELECT TOP 10 ci.GCID,
		atnm.RealCID,
		cia.Count AS 'PoUpsCount', 
		cia.FirstInteractionDate, 
		cia.LastInteractionDate,
		CASE WHEN cd.Gcid IS NULL THEN 0 ELSE 1 END AS 'HasCompletedFTP',
	        cd.BeginDate AS 'CompletionFTPDate',
		DATEDIFF(DAY,cia.FirstInteractionDate,cia.LastInteractionDate) as 'DaysFromFirstToLast',
                atnm.ApproprietnessScore_Status,
		atnm.AT_Date
FROM [BI_DB_dbo].[External_ComplianceStateDB_Compliance_CustomerInteractionActionCounts] as cia
INNER JOIN [BI_DB_dbo].[External_ComplianceStateDB_Compliance_CustomerInteractions] ci ON cia.CustomerInteractionId = ci.CustomerInteractionId
INNER JOIN [BI_DB_dbo].[External_ComplianceStateDB_Compliance_UserInteractionDetails] ui ON ci.UserInteractionId = ui.UserInteractionId
					AND ui.UserInteractionTypeId = 4 AND ui.UserInteractionId = 22 
LEFT JOIN [BI_DB_dbo].[External_SettingsDB_Settings_CustomerData] cd ON cd.Gcid=ci.GCID
			AND cd.SelectedValue IN ('2') AND cd.ResourceId=5907
INNER JOIN BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market atnm ON ci.GCID = atnm.GCID
WHERE cia.UserInteractionActionId = 2 AND atnm.RealCID=<[Parameters].[Parameter 2]>
GROUP BY ci.GCID,
		atnm.RealCID,
		cia.Count, 
		cia.FirstInteractionDate, 
		cia.LastInteractionDate,
		CASE WHEN cd.Gcid IS NULL THEN 0 ELSE 1 END,
                cd.BeginDate,
		DATEDIFF(DAY,cia.FirstInteractionDate,cia.LastInteractionDate),
                atnm.ApproprietnessScore_Status,
		atnm.AT_Date