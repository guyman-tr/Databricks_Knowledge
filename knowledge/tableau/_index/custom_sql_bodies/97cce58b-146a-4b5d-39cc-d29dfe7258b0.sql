SELECT
ops.*,
dc.Name as Country,
dc.Region, m.Email
FROM BI_DB.[dbo].[BI_DB_TicketsForOPS_NEW] ops 
left join DWH.dbo.Dim_Customer c on c.RealCID=ops.CID
LEFT JOIN DWH.dbo.Dim_Country dc on dc.CountryID=c.CountryID
left JOIN [AZR-W-REAL-DB-2-BIDBUser].etoro.BackOffice.Manager m ON m.FirstName + ' ' + m.LastName=ops.AssignedTo COLLATE Latin1_General_100_BIN