SELECT bdcba.* , ra.LastLoggedIn
FROM BI_DB_dbo.BI_DB_CopyBlockedAUM bdcba
LEFT join BI_DB_dbo.BI_DB_DailyRiskAlert ra ON ra.CID = bdcba.CID