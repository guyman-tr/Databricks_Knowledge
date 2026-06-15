SELECT  
ci.GCID,
cia.Count,
cia.FirstInteractionDate,
cia.LastInteractionDate,
cia.UserInteractionActionId,
ui.UserInteractionTypeId,
ui.UserInteractionId,
cia.CustomerInteractionId,
ci.StateAdditionalData
FROM [BI_DB_dbo].[External_ComplianceStateDB_Compliance_CustomerInteractionActionCounts] cia
INNER JOIN [BI_DB_dbo].[External_ComplianceStateDB_Compliance_CustomerInteractions] ci ON cia.CustomerInteractionId = ci.CustomerInteractionId
INNER JOIN [BI_DB_dbo].[External_ComplianceStateDB_Compliance_UserInteractionDetails] ui ON ci.UserInteractionId = ui.UserInteractionId
WHERE --GCID = <GCID here> and 
ui.UserInteractionId = 39 AND cia.UserInteractionActionId IN (1,14,15)