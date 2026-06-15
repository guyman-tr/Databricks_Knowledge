SELECT *
FROM BI_DB_dbo.BI_DB_Wire_PIP_Report bdwpr
where PaymentDate>=<[Parameters].[Parameter 1]> and PaymentDate<=<[Parameters].[Parameter 2]>