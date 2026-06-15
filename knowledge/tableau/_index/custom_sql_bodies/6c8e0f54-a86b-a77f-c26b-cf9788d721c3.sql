SELECT
'In' AS  Source
, eft.InstrumentID
  , eft.CryptoId
 , eft.CryptoName as Crypto
 , eiw.Id as 'Omnibus Wallet ID'
 , eiw.Address as 'Omnibus Address'
 , eiw.InternalType as 'Omnibus Type'
 ,  case when eft.CryptoId = eft.BlockchainCryptoId then 'Main Crypto' else 'ERC20'end 'Crypto Type'
 , eft.TranDate
 , sum(eft.AmountUSD) as 'USD' -- In: User Sell
 , sum(eft.Amount) as 'Unit' -- In: User Sell
 from EXW_dbo.EXW_FactTransactions eft 
 JOIN EXW_dbo.EXW_InternalWallet eiw on WalletID= eiw.Id and eft.CryptoId = eiw.CryptoId
where eft.ActionTypeID=1 and eft.GCID > 0  and eft.TranStatusID=2 
Group by   eft.CryptoId  , eft.CryptoName, eft.TranDate, eiw.Id,  eiw.Address ,eiw.InternalType
,case when eft.CryptoId = eft.BlockchainCryptoId then 'Main Crypto' else 'ERC20'END
, eft.InstrumentID

UNION ALL
--#out omnibus send
Select 
'Out' AS  Source
, eft.InstrumentID
 , eft.CryptoId 
 , eft.CryptoName as Crypto 
 , eiw.Id as 'Omnibus Wallet ID'
 , eiw.Address as 'Omnibus Address'
 , eiw.InternalType as 'Omnibus Type'
 , case when eft.CryptoId = eft.BlockchainCryptoId then 'Main Crypto' else 'ERC20'end 'Crypto Type'
 , eft.TranDate
 , sum(eft.AmountUSD) as 'USD' -- Out
 , sum(eft.Amount) as 'Unit' -- Out
 from EXW_dbo.EXW_FactTransactions eft 
 JOIN EXW_dbo.EXW_InternalWallet eiw on WalletID= eiw.Id and eft.CryptoId = eiw.CryptoId
where 
eft.ActionTypeID=1 
and eft.GCID <= 0 and eft.TranStatusID=2
GROUP BY eft.CryptoId, eft.WalletID, eft.TranDate,eft.CryptoName, eiw.Id, eiw.InternalType, eiw.Address 
, case when eft.CryptoId = eft.BlockchainCryptoId then 'Main Crypto' else 'ERC20'end 
, eft.InstrumentID