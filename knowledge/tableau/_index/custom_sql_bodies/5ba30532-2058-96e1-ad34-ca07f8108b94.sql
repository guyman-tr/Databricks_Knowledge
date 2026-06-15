SELECT t.*,
       c.GuruStatusID,
	   dgs.GuruStatusName
FROM BI_DB_dbo.BI_DB_SuspiciousActivityTrading_Investing t
left join DWH_dbo.Dim_Customer c
	ON t.RootCID = c.RealCID
LEFT join DWH_dbo.Dim_GuruStatus dgs
	ON dgs.GuruStatusID= c.GuruStatusID