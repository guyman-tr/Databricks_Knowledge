select * from BI_DB_dbo.BI_DB_Finance_eToro_vs_Positions
where DateID between 
CAST(FORMAT(CAST(<[Parameters].[Parameter 1 1]> AS DATE),'yyyyMMdd') as INT)
and 
CAST(FORMAT(CAST(<[Parameters].[Parameter 2 1]> AS DATE),'yyyyMMdd') as INT)