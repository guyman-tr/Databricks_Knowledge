SELECT *
FROM BI_DB_dbo.BI_DB_V_StockMargin_Balances bdvsmb
WHERE bdvsmb.DateID = CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)