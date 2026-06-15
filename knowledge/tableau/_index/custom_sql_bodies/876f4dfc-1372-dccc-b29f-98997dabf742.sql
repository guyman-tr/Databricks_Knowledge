SELECT *
FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData bdcmpfd
WHERE bdcmpfd.ActiveDate>=DATEADD(mm,-13,GETDATE()-1)