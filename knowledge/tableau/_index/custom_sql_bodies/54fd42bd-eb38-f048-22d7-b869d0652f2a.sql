SELECT *

FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New bdcbcln
where bdcbcln.DateID between CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT)
and CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)