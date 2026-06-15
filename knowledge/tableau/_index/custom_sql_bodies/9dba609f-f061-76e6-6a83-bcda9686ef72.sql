SELECT bdsmu.AccountManagerID
		,bdsmu.FirstName +' '+ LastName AS Name 
		,bdsmu.Team
		,bdsmu.IsActive
		,bdsmu.Position
		,sur.[SurveyID]
		  ,sur.[OwnerId] OwnerID
		  ,sur.[SurveyName]
		  ,sur.[CreatedDate]
		  ,sur.[CreatedyID]
		  ,sur.[SystemModstamp]
		  ,sur.[CustomerEngagementID]
		  ,sur.AccountOwner
		  ,Case When LEFT(sur.[cSAT],1) = 0 THEN NULL ELSE sur.[cSAT] END cSAT
		  ,Case When LEFT(sur.[Q_ProfessionalService],1) = 0 THEN NULL ELSE sur.[Q_ProfessionalService] END Q_ProfessionalService
		  ,Case When LEFT(sur.[Q_HelpFulEconomic],1) = 0 THEN NULL ELSE sur.[Q_HelpFulEconomic] END Q_HelpFulEconomic
		  ,Case When LEFT(sur.[Q_Investmentchoices],1) = 0 THEN NULL ELSE  sur.[Q_Investmentchoices] END Q_Investmentchoices
		  ,Case When LEFT(sur.[Q_Newproducts],1) = 0 THEN NULL ELSE sur.[Q_Newproducts] END Q_Newproducts
		  ,sur.[Q_WhichProducts1]
		  ,sur.[Q_WhichProducts2]
		  ,sur.[UpdateDate]
		  , EngagementName
		  ,sur.CreatedById CreatedByID
FROM BI_DB_dbo.External_BI_OUTPUT_Customer_Customer_Support_Agent_User bdsmu
LEFT JOIN (SELECT  sur.[SurveyID]
		  ,sur.[OwnerId] 
		  ,sur.[SurveyName]
		  ,sur.[CreatedDate]
		  ,NULL AS [CreatedyID]
		  ,sur.[SystemModstamp]
		  ,sur.[cSAT]
		  ,sur.[CustomerEngagementID]
		  ,ce.AccountOwner
		  ,sur.[Q_ProfessionalService]
		  ,sur.[Q_HelpFulEconomic]
		  ,sur.[Q_Investmentchoices]
		  ,sur.[Q_Newproducts]
		  ,sur.[Q_WhichProducts1]
		  ,sur.[Q_WhichProducts2]
		  ,sur.[UpdateDate]
		  ,ce.Name EngagementName
		  ,ce.CreatedById 
		  FROM [BI_DB_dbo].[External_BI_OUTPUT_Customer_Facing_AM_Survey] sur
		  INNER JOIN BI_DB_dbo.External_BI_OUTPUT_Customer_Customer_Engagement ce
		  ON sur.CustomerEngagementID = ce.Id) sur
ON bdsmu.ID = sur.CreatedById
AND sur.CreatedDate>=DATEADD(mm,-5,SYSUTCDATETIME())
WHERE bdsmu.ToDate = '9999-12-31T00:00:00.000Z'