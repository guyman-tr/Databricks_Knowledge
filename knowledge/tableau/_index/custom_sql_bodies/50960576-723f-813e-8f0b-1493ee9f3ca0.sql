SELECT 
bdadh.*,
pl.Name AS Club
FROM BI_DB_dbo.BI_DB_AllDeposits bdadh
JOIN DWH_dbo.Dim_Customer c ON c.RealCID=bdadh.CID
JOIN DWH_dbo.Dim_PlayerLevel pl ON pl.PlayerLevelID=c.PlayerLevelID
WHERE bdadh.ModificationDate>=DATEADD(Month, DATEDIFF(Month, 0, DATEADD(m, - 3, CURRENT_TIMESTAMP)), 0)