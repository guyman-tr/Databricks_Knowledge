SELECT 
ww.Gcid,
av.WalletId,
av.ProviderStatus,
av.IsPositiveDecision, 
av.IsSend, 
av.Address, 
av.Amount, 
av.Created
, av.DetailsJson
, av.CryptoId
, ect.Name AS MarketRatesCurrencySymbol
, av.CorrelationId
 , dc.PlayerLevelID
 , dc1.RegisteredReal as 'Etoro Registration Date'
 ,CASE
		WHEN dc.IsTestAccount =1 THEN 'TestUser'
		When dc.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS RealUser
	, p.Name as 'Club'
   , dc.Country
   , dc.Region
   ,dc.Regulation
FROM  EXW_Wallet.AmlValidations   av
join EXW_Wallet.CustomerWalletsView ww ON av.WalletId =ww.Id AND av.CryptoId =ww.CryptoId   AND Gcid >0
JOIN EXW_Wallet.CryptoTypes ect  ON av.CryptoId =ect.CryptoID
JOIN EXW_dbo.EXW_DimUser  dc on dc.GCID = ww.Gcid
JOIN DWH_dbo.Dim_Customer dc1 ON dc.RealCID = dc1.RealCID
join DWH_dbo.Dim_PlayerLevel p on dc.PlayerLevelID = p.PlayerLevelID 
WHERE   1=1
AND av.AmlProviderId=1