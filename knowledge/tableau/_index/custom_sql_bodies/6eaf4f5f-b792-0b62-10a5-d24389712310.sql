/****** Script for SelectTopNRows command from SSMS  ******/
SELECT ft.GCID
      ,ft.RealCID
      ,ft.CryptoId
      ,ft.CryptoName
    --  ,ft.InstrumentID
        ,ft.TranID
       ,ft.TranDate
      ,ft.TranDateID
      ,ft.Amount
	  , ft.AmountUSD 
      --  ,ft.SenderAddress
  -- ,ft.ReciverAddress
    -- ,ft.IsRedeem
     -- ,ft.IsConversion
   --   ,ft.IsPayment 
      ,ft.BlockchainCryptoId
      ,ft.BlockchainCryptoName
	  ,due.Country
   , due.Region
   , due.PlayerLevelID
   , dc.RegisteredReal as 'Etoro Registration Date'
   , ft.AMLProviderStatus 
   , CASE when fca.DateID is NOT NULL then 'Yes' ELSE 'No' end VPN
,CASE
		WHEN due.Username LIKE '%RedeemProd%' OR
			due.Username LIKE '%RedeemProd%' OR
			due.Username LIKE '%WalletProd%' OR
			due.Username LIKE '%InternalProd%' OR
			due.Username LIKE '%NoWalletProd' OR
                        due.Username ='RonaMaltz' OR
                        due.Username = 'DanGanon'

THEN 'TestUser'

		When dc.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS RealUser
, p.Name as 'Club'
       ,CASE 
   	When due.Country ='United States' THEN 'US'
   	   	ELSE 'NotUS'
   END isUS
  FROM  EXW.dbo.EXW_FactTransactions ft
  Left JOIN EXW.dbo.EXW_DimUser_Enriched due ON ft.GCID = due.GCID
LEFT JOIN DWH.[dbo].[Dim_Customer] dc on dc.RealCID = ft.RealCID
Left join [DWH].[dbo].[Dim_PlayerLevel] p on due.PlayerLevelID = p.PlayerLevelID 
left JOIN 
  (SELECT DISTINCT fca.DateID, fca.RealCID FROM DWH.[dbo].[Fact_CustomerAction] fca 
  WHERE fca.ActionTypeID =14 and fca.ProxyType ='VPN'  and fca.DateID >=   CONVERT(VARCHAR(35),dateadd(month, -1, cast(getdate() as date)),112)) fca
on ft.RealCID = fca.RealCID and fca.DateID= ft.TranDateID 
WHERE 1=1
and ft.GCID>0
and ft.TranStatusID =2
and ft.ActionTypeID =1
and ft.IsConversion =0
 --and ft.TranDate >= getdate()-30
and ft.TranDate >=DATEADD(month, -1, GETDATE())