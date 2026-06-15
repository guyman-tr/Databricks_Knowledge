select wi.BlockchainCryptoId AS CryptoID
, wi.BlockchainCryptoName as CryptoName
, wi.CryptoID AS CryptoIdERC
, wi.CryptoName AS CryptoNameERC
, wi.WalletStatus 
,SUM(case when Occupied = 1 AND wi.Allocated >GETDATE()-120 THEN  1 else 0 end) as Occupied 
,SUM(case when Occupied = 0 then 1 else 0 end) as FreeInventory 
	--	sum(case when IsPromotionReady = 1 and WalletStatus = 'FundingVerified' and Occupied = 1 and CryptoID = 2 then 1 else 0  end) ETH_Prom_Occupied,
	--	sum(case when IsPromotionReady = 1 and WalletStatus = 'FundingVerified' and Occupied = 0 and CryptoID = 2 then 1 else 0  end) ETH_Prom_Available
from EXW_dbo.EXW_WalletInventory wi with (NOLOcK)
WHERE wi.BlockchainCryptoId =wi.CryptoID
group by wi.CryptoID,CryptoName,  wi.WalletStatus, wi.BlockchainCryptoId , wi.BlockchainCryptoName