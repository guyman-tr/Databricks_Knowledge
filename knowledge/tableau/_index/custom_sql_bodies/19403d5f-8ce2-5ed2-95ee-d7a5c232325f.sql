SELECT *, CAST(CONVERT(VARCHAR(6), registered , 112) AS INT)as YearMonthRegistered 
FROM BI_DB_dbo.[BI_DB_M_Affiliates_FraudMonitoring_Relations]