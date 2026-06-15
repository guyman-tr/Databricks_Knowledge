SELECT
    ewi.WalletStatus
   ,ewi.CryptoName  
   ,sum(Case when  ewi.Allocated is not null and ewi.GCID>0  THEN 1 ELSE 0 END) AS 'Allocated Total'
   ,sum(CASE WHEN ewi.Allocated >= cast(GETDATE()  as Date) THEN 1 ELSE 0 END) AS 'Allocated Today'
   ,sum(CASE WHEN ewi.Allocated  = cast(GETDATE()-1  as Date) THEN 1 ELSE 0 END) AS 'Allocated T-1'
   ,sum(CASE WHEN ewi.Allocated >= cast(GETDATE()-2  as Date) THEN 1 ELSE 0 END) AS 'Allocated T-2'
   ,sum(CASE WHEN ewi.Allocated >= cast(GETDATE()-3  as Date) THEN 1 ELSE 0 END) AS 'Allocated T-3'
   ,sum(CASE WHEN ewi.Allocated >= cast(GETDATE()-1 as Date) THEN 1 ELSE 0 END) AS 'Allocated T-1 to Date'
   ,sum(CASE WHEN ewi.Allocated >= cast(GETDATE()-7 as Date) THEN 1 ELSE 0 END) AS 'Allocated T-7 to Date'
   ,sum(CASE WHEN ewi.Allocated >= cast(GETDATE()-30 as Date) THEN 1 ELSE 0 END) AS 'Allocated T-30 to Date'
   ,sum(CASE WHEN ewi.Allocated >= cast(GETDATE()-90 as Date) THEN 1 ELSE 0 END) AS 'Allocated T-90 to Date'
   ,sum(CASE WHEN ewi.WalletStatus  = 'FundingVerified' and ewi.Occupied=0 and IsPromotionReady=1 THEN 1 ELSE 0 END) AS 'Funded Free'
   ,sum(CASE WHEN ewi.WalletStatus  in ( 'FundingVerified','Verified') and ewi.Occupied=0  THEN 1 ELSE 0 END) AS 'Available'
   ,SUM(CASE WHEN ewi.WalletStatus IN ('FundingFailed','FundingInitiated') and ewi.Occupied=0  THEN 1 ELSE 0 END) AS 'FundingFailed/Initiated'
   ,sum(CASE WHEN  ewi.Occupied=0  THEN 1 ELSE 0 END) AS 'AvailableTotal'
   ,sum(CASE WHEN ewi.WalletStatus ='Pending' and ewi.Occupied=0  THEN 1 ELSE 0 END) AS 'Pending Available'
   ,sum(CASE WHEN  ewi.Occupied=1  and ewi.GCID>0 THEN 1 ELSE 0 END) AS 'Occupied'
   FROM EXW_dbo.EXW_WalletInventory ewi
WHERE ewi.BlockchainCryptoId =ewi.CryptoID
GROUP BY
  ewi.CryptoName  
      ,ewi.WalletStatus