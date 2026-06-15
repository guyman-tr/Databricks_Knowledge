SELECT dcr.*, dc.GCID
FROM BI_DB_dbo.Dealing_CryptoRebate dcr
JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID=dcr.CID