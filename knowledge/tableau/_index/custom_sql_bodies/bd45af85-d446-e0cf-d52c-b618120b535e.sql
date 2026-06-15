SELECT 
dense_rank() over (partition by ft.TranDate order by ft.WalletID ASC) + dense_rank() over (partition by ft.TranDate order by ft.WalletID desc) - 1 as 'Distinct Wallets Count'
,COUNT(ft.TranID) OVER(PARTITION BY ft.TranDate ORDER BY ft.TranDate DESC) AS 'Count TranID' 
, sum(ft.Amount) OVER(PARTITION BY ft.TranDate ORDER BY ft.TranDate DESC) AS 'Sum Amount'
, sum(ft.AmountUSD) OVER(PARTITION BY ft.TranDate ORDER BY ft.TranDate DESC) AS 'Sum Amount USD'
,ft.TranDate
, ft.WalletID
, ft.TranID
 ,ft.CryptoName
, ft.ReciverAddress
, ft.SenderAddress
, ft.BlockchainTransactionId
, ft.Amount
, ft.AmountUSD
, ft.GCID
, ft.ActionTypeName
, ft.ActionTypeID
, edue.Country
, edue.PlayerLevelID
, edue.Club

,Case WHEN edue.IsTestAccount =1 THEN  'TestUser'
        When edue.IsValidCustomer =0 then 'eTorian'
        ELSE 'RealUser'
    END AS IsRealUser
FROM  EXW_dbo.EXW_FactTransactions ft
Left   join EXW_dbo.EXW_DimUser  edue on edue.GCID =ft.GCID
WHERE 1=1
 and ft.IsRedeem =1
and ft.GCID >0
and ft.ActionTypeID =2