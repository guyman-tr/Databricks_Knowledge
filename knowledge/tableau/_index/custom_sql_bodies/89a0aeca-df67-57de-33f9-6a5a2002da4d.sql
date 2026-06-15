SELECT bdsc.* 
      ,us.ReportsTo_BOB
	  ,sfu.Country
      ,sfu1.Country TeamLeadCountry
	  ,sfu.IsActive
      ,us.IsOutsourced
      ,sfu.CreatedDate StartWorking
FROM BI_DB..BI_DB_SF_Chats bdsc
LEFT JOIN [BI_DB].[dbo].[BI_DB_SF_Users] us 
ON bdsc.Manager = us.FullName
LEFT JOIN [SalesForce_DB_Prod].[dbo].[SalesForce_User] sfu
ON bdsc.Manager = sfu.Name
LEFT JOIN [SalesForce_DB_Prod].[dbo].[SalesForce_User] sfu1
ON us.ReportsToID_BOB = sfu1.Id
WHERE bdsc.RequestTime >= '20210101'