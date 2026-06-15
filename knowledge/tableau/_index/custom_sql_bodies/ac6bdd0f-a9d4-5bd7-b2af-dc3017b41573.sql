SELECT 
h.ReportDate
,h.CryptoID
, ct.Name AS Crypto
, h.WalletStatus
, h.TotalAllocated
, h.TotalFreeInventory, h.PromotionReadyAllocated, h.PromotionReadyAvailable
, h.AllocatedToday
	FROM EXW_dbo.Hourly_WalletInventory h 
	JOIN EXW_Wallet.CryptoTypes ct	ON 		ct.CryptoID = h.CryptoID
	WHERE h.ReportDate = CAST(GETDATE() AS DATE) --AND h.WalletStatus IN ('FundingVerified', 'Verified')