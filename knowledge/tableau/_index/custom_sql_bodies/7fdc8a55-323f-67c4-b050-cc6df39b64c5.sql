SELECT DISTINCT CAST(Allocated AS DATE) as Date, CryptoID,  GCID, GCIDRank, WalletRank 
FROM
(
SELECT ewi.CryptoID, ewi.GCID, ewi.Allocated,
	ROW_NUMBER() OVER (PARTITION BY ewi.GCID ORDER BY ewi.Allocated) AS GCIDRank,
	ROW_NUMBER() OVER (PARTITION BY ewi.WalletID ORDER BY ewi.Allocated) AS WalletRank
FROM EXW_dbo.EXW_WalletInventory ewi with (NOLOcK) where ewi.GCID > 0
) a
WHERE  (GCIDRank = 1 OR WalletRank = 1)