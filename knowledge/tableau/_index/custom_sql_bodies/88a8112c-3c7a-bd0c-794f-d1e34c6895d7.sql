select *
FROM eMoney_dbo.eMoney_Daily_Shortfall_CID_Level mdscl
where DateID>=CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
and DateID<=CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)