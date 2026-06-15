SELECT t.*,
       GuruStatusID
FROM BI_DB.dbo.BI_DB_SuspiciousActivityTrading_24H t
left join DWH.dbo.Dim_Customer c
	ON t.RootCID = c.RealCID