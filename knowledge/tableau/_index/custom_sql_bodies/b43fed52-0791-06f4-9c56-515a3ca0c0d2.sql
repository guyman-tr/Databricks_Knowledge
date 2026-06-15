/****** Script for SelectTopNRows command from SSMS  ******/
SELECT ft.GCID
      ,ft.RealCID
         ,ft.CryptoName
         ,ft.TranID
        ,ft.TranStatus
      ,ft.TranDate
      ,ft.TranDateID
      ,ft.Amount
        ,ft.AmountUSD
       ,ft.TransactionType
      ,ft.IsRedeem
      ,ft.IsConversion
      ,ft.IsPayment
      ,ft.BlockchainCryptoId
      ,ft.BlockchainCryptoName
	  ,due.Country
   , due.Region
   , due.Club
   , ft.ActionTypeID 
  --, ex.amount as 'Exchange Amount'
 -- , ex.uid
-- , Case when ex.address is NULL THEN 'N' ELSE 'Y' end IfSentToExchange
,CASE
		WHEN due.IsTestAccount =1 THEN 'TestUser'
		WHEN due.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS RealUser
,CASE 
   	When due.RegulationID  IN (6,7,8) THEN 'US' ELSE 'NotUS' END isUS

  FROM  EXW.dbo.EXW_FactTransactions ft
JOIN EXW_DimUser due ON ft.GCID = due.GCID
--left JOIN [ThirdParty_Fivetran].[Fivetran].[gsheets].[exw_exchange_data_for_wallet] ex  ON ex.address COLLATE Latin1_General_100_BIN  =ft.ReciverAddress and ft.TranDate =ex.date 
--and UPPER(ex.currency_id) COLLATE Latin1_General_100_BIN=ft.CryptoName
--and ex.amount=ft.Amount
WHERE due.IsValidCustomer =1
AND due.IsTestAccount =0 
 AND ft.ActionTypeID =1
and ft.TransactionTypeID =1  --CustomerMoneyOut
 and ft.TranDate >= CAST(getdate()-40 AS DATE)