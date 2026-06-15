select tr.GCID
      ,tr.RealCID
      ,tr.CryptoId
      ,tr.CryptoName
     -- ,tr.InstrumentID
      ,tr.WalletID
      ,tr.TranID
      ,tr.TranStatusID
      ,tr.TranStatus
      ,tr.TranDate
      ,tr.TranDateID
      ,tr.Amount
      ,tr.EtoroFees
      ,tr.ProviderFees
      ,tr.FeeExchangeRate
      ,tr.BlockchainFees
      ,tr.EstimatedBlockchainFee
      ,tr.ActionTypeID
      ,tr.ActionTypeName
      ,tr.AmountUSD
      ,tr.EtoroFeesUSD
      ,tr.BlockchainFeesUSD
      ,tr.EstimatedBlockchainFeesUSD
         ,tr.IsEtoroFee
         ,tr.TransactionTypeID
      ,tr.TransactionType
      ,tr.IsRedeem
      ,tr.IsConversion
      ,tr.IsPayment
      ,tr.BlockchainCryptoId
      ,tr.BlockchainCryptoName
   , dc1.Name AS Country
, dc1.Region
, p.Name as 'Club'
,dr.Name AS Regulation
,CASE
		WHEN 
			dc.IsTestAccount=1     THEN 'TestUser'
		When dc.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
 
 FROM
 [EXW].[dbo].EXW_FactTransactions tr with (NOLOcK) 
JOIN EXW.dbo.EXW_DimUser  dc WITH (nolock) on dc.RealCID= tr.RealCID
 join
(
SELECT fsc.RealCID AS CID, d.DateKey as DateID, fsc.CountryID, fsc.RegulationID, fsc.PlayerLevelID
FROM DWH..Fact_SnapshotCustomer fsc WITH (nolock)
	JOIN DWH..Dim_Range dr 		ON fsc.DateRangeID = dr.DateRangeID
	join DWH.dbo.Dim_Date d 	   on d.DateKey between FromDateID and ToDateID
WHERE 1=1 
	--AND fsc.CountryID = 79
	) b
	on tr.RealCID =b.CID and tr.TranDateID = b.DateID
	JOIN DWH.dbo.Dim_Country dc1 ON b.CountryID=dc1.CountryID
	JOIN DWH.dbo.Dim_Regulation dr ON b.RegulationID =dr.DWHRegulationID
	join [DWH].[dbo].[Dim_PlayerLevel] p WITH (nolock) on b.PlayerLevelID = p.PlayerLevelID
	where tr.TranDateID >=  cast(CONVERT (VARCHAR(8) , dateadd(month,-4,getdate()), 112 ) AS INT)