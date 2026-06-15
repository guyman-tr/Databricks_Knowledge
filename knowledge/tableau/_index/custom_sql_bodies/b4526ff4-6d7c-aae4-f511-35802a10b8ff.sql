SELECT  
	  s.WalletId
	  ,s.Amount
	  ,s.CorrelationId
		  ,s.Occurred 'Staking Occurred' 
	  ,strx.ExternalStakingAddress
	  ,strx.StakingId
	 -- ,strx.Occurred  'Staking TRANSACTION Occurred' 
	  ,edu.GCID
	  ,edu.RealCID
	  ,edu.VerificationLevelID
	  ,edu.Country
	   ,edu.IsTestAccount
	  ,edu.IsValidCustomer
		  ,edu.Regulation
	  ,edu.Club
	  , p.FullDate AS 'Rate Date'
	  , p.AvgPrice
	  , CAST(DATEADD(mm, DATEDIFF(mm, 0, s.Occurred), 0) AS DATE) FirstDayMonthStaking
	 	  , (SELECT TOP 1 Allocated FROM EXW.dbo.EXW_WalletInventory  WHERE GCID>0 AND CryptoID=2 AND GCID =edu.GCID ORDER BY Allocated ASC) EthWalletJoinDate
	 FROM  ETL_StakingStaking s
    LEFT     JOIN ETL_StakingStakingTransactions strx  (NOLOCK) ON strx.StakingId = s.Id
	 JOIN EXW.dbo.ETL_CustomerWalletsView wv ON wv.Id= s.WalletId AND wv.CryptoId=2 
	JOIN EXW_DimUser edu ON wv.Gcid = edu.GCID
  JOIN (
  	   select TOP 1  epd.FullDate, epd.AvgPrice,epd.CryptoID FROM EXW.dbo.EXW_PriceDaily epd WHERE   DATEPART(WEEKDAY, epd.FullDate) =7  AND epd.CryptoID =2 
	   ORDER BY epd.FullDateID DESC    )p
	   ON p.CryptoID=s.CryptoId