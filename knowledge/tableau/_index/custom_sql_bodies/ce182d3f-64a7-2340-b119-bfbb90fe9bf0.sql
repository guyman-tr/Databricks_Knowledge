SELECT *
FROM BI_DB.dbo.BI_DB_SF_Cases_Panel bdscp
WHERE bdscp.ActionType_AtOpen LIKE '%AML%'
AND bdscp.CreatedDate >= '20230101'