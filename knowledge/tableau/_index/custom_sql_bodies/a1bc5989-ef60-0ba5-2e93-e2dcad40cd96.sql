SELECT
COUNT(ewi.WalletID)Wallets
, CAST(ewi.Created AS Date)CreatedDate
, ewi.CryptoName
, ewi.WalletStatus
FROM EXW_dbo.EXW_WalletInventory ewi
 WHERE ewi.BlockchainCryptoId =ewi.CryptoID
GROUP BY CAST(ewi.Created AS Date), ewi.CryptoName,ewi.WalletStatus