SELECT a1.EndofMonth,
Country,
a1.[Client Type],
a1.Clients,
a1.[Clients Generated Revenue],
a1.Revenue
FROM BI_DB_dbo.BI_DB_Payoneer_Revenue_Report a1
WHERE a1.Country IN ('Argentina','Brazil','Egypt','Morocco','Philippines','Thailand','Ukraine','United Arab Emirates','Vietnam')
and a1.EndofMonth<DATEADD(month, DATEDIFF(month, 0,getdate()), 0)