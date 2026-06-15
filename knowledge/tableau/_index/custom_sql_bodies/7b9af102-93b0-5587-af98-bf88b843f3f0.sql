select 
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
, cmrm.MarketRatesCurrencySymbol
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
   from [Wallet_Server_WalletDB].[WalletDB].Wallet.AmlValidations av
join [Wallet_Server_WalletDB].[WalletDB].wallet.Wallets ww on av.WalletId=ww.WalletId
JOIN [Wallet_Server_WalletDB].[WalletDB].Wallet.CryptoMarketRatesMappings cmrm ON cmrm.CryptoId = av.CryptoId
JOIN EXW.[dbo].[EXW_DimUser]  dc on dc.GCID = ww.Gcid
JOIN DWH.dbo.Dim_Customer dc1 ON dc.RealCID = dc1.RealCID
join [DWH].[dbo].[Dim_PlayerLevel] p on dc.PlayerLevelID = p.PlayerLevelID 
where  1=1
and av.AmlProviderId=1 
and av.Address NOT IN 
(select distinct Address from [Wallet_Server_WalletDB].[WalletDB].Wallet.CustomerWalletsView where Gcid=0)