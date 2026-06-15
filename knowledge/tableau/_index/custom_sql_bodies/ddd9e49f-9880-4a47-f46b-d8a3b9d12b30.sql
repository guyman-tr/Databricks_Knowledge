select 
ww.Gcid
, dc.RealCID
,av.WalletId
,av.ProviderStatus
,av.IsPositiveDecision 
,av.IsSend 
,av.Address 
,av.Amount
,av.Amount*ep.AvgPrice AS USD
,av.Created
, av.DetailsJson
, av.CryptoId
, cmrm.MarketRatesCurrencySymbol
, av.CorrelationId
 , dc.PlayerLevelID
 , dc.RegisteredReal as 'Etoro Registration Date'
 ,CASE
		WHEN dc.UserName LIKE '%RedeemProd%' OR
			dc.UserName LIKE '%RedeemProd%' OR
			dc.UserName LIKE '%WalletProd%' OR
			dc.UserName LIKE '%InternalProd%' OR
			dc.UserName LIKE '%NoWalletProd' OR
                        dc.UserName ='RonaMaltz' OR
                        dc.UserName = 'DanGanon'

THEN 'TestUser'

		When dc.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS RealUser
	, p.Name as 'Club'
   , c.Name as 'Country'
   , c.Region
   ,dr.Name as 'Regulation'
from [Wallet_Server_WalletDB].[WalletDB].Wallet.AmlValidations av
join [Wallet_Server_WalletDB].[WalletDB].wallet.Wallets ww on av.WalletId=ww.WalletId
JOIN [Wallet_Server_WalletDB].[WalletDB].Wallet.CryptoMarketRatesMappings cmrm ON cmrm.CryptoId = av.CryptoId
LEFT JOIN DWH.[dbo].[Dim_Customer] dc on dc.GCID = ww.Gcid
LEFT join [DWH].[dbo].[Dim_PlayerLevel] p on dc.PlayerLevelID = p.PlayerLevelID 
LEFT JOIN DWH..Dim_Regulation dr ON dc.RegulationID = dr.DWHRegulationID
LEFT JOIN [DWH].[dbo].Dim_Country c on dc.CountryID=c.CountryID
LEFT JOIN dbo.EXW_PriceDaily ep ON av.CryptoId =ep.CryptoID and ep.FullDate = cast(av.Created AS DATE)
where  1=1
and av.AmlProviderId=1 
and av.Address NOT IN 
(select distinct Address from [Wallet_Server_WalletDB].[WalletDB].Wallet.CustomerWalletsView where Gcid=0)
and ProviderStatus='Red'