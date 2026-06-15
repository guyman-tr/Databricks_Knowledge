SELECT CONVERT(DATE,ut.CreatedDate_SF) Date
      ,syn.full_name AM
      ,syn.position Position
	  ,syn.desk Desk
	  ,syn.manager_type ManagerType
FROM [BI_DB].[dbo].[BI_DB_UsageTracking_SF] ut WITH (NOLOCK)
INNER JOIN [BI_DB].[dbo].[Syn_gsheets.customer_managers] syn WITH (NOLOCK)
ON ut.ManagerID = syn.manager_id
AND syn.is_active = 1
WHERE  ut.ActionName IN ('Phone_Call_Succeed__c','Contacted__c')
GROUP BY CONVERT(DATE,ut.CreatedDate_SF)
        ,syn.full_name 
        ,syn.position 
	    ,syn.desk
		,syn.manager_type 
HAVING COUNT(DISTINCT CID)>=5