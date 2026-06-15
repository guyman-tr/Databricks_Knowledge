SELECT DISTINCT edu.GCID, edu.RealCID , ecwv.Address
FROM EXW_Wallet.CustomerWalletsView ecwv 
JOIN EXW_dbo.EXW_DimUser edu ON ecwv.Gcid =edu.GCID
WHERE ecwv.Address =<[Parameters].[Parameter 1]>