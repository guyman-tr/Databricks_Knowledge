SELECT bdscp.CaseNumber, bdscp.Owner_Last, bdsmu.Name, bdsmu.Department, bdsmu.Title, sg.Name AS 'CaseOwnerLast'
FROM BI_DB.dbo.BI_DB_SF_Cases_Panel bdscp
LEFT JOIN BI_DB.dbo.BI_DB_SF_M_Users bdsmu ON bdsmu.Id = bdscp.Owner_Last
LEFT JOIN [SalesForce_DB_Prod].[dbo].[SalesForce_Group] sg ON sg.Id = bdscp.Owner_Last
WHERE bdsmu.ToDate = '9999-12-31'