SELECT
  eft.SenderAddress
, eft.ReciverAddress
, eft.TranStatus
, eft.WalletID
, eft.AmountUSD
, eft.LastStatusUpdateOccurred
, eft.Amount
, eft.CryptoName
, eft.CryptoId
, eiw.Address OmnibusAddress
, eiw.InternalType
, eiw.InternalWalletTypeId
, eft.IsConversion
, eft.BlockchainTransactionId
, eft.BlockchainCryptoName
, eft.TranDate
,CASE
WHEN UPPER(eft.SenderAddress)
IN (
 UPPER('bc1qsyhm5esxsg3tw5pn0pj4t6hr2495ry5rscpy4x')
,UPPER('0x1B247755FEcDe192587fd92751D88235833420E7')
,UPPER('GAHO7ROH62UG6ZE3LW6OG4EQQ6D2S3CPSFVTODDTC6QY6RMEHCCVWLXX')
,UPPER('rPxBxMcm9T4DBqb9o7ZXKv4xvbRxGs85La')
,UPPER('bitcoincash:qzccwn8g0cyzl4d07w0p3ct2zktc4nsm7qghxc33kl')
,UPPER('ltc1qj6ax755cej8hcz6padp7xk4p05w025qfarf0pj')) THEN 'Seqwit'
WHEN UPPER(eft.SenderAddress)
IN (
 UPPER('1Cn5LxLDiC36w7Pq1QMGYMmRq5djYLVYab')
,UPPER('1HBggnwo9RF8pkPDG4B5RsKprfgEzYZbKg')
,UPPER('LYxvxi35d1DacTG1bJ9RiohQxGHtS7zYyf')) THEN 'Legacy' 
ELSE 'NA' END SenderType
 
FROM EXW_dbo.EXW_FactTransactions eft  
JOIN EXW_dbo.EXW_InternalWallet eiw ON eft.CryptoId = eiw.CryptoId 
--AND eiw.Address =eft.ReciverAddress
AND EXW_dbo.RemoveSuffix (EXW_dbo.RemovePrefix(eiw.Address, ':'), '?') = 
        EXW_dbo.RemoveSuffix(EXW_dbo.RemovePrefix(eft.ReciverAddress,  ':'), '?')
AND eft.ActionTypeID =2
AND eft.GCID =0 
AND eft.IsConversion =0
 AND  UPPER(eft.SenderAddress) IN 
 (UPPER( '1Cn5LxLDiC36w7Pq1QMGYMmRq5djYLVYab')
,UPPER('1HBggnwo9RF8pkPDG4B5RsKprfgEzYZbKg')
,UPPER('LYxvxi35d1DacTG1bJ9RiohQxGHtS7zYyf')
,UPPER('bc1qsyhm5esxsg3tw5pn0pj4t6hr2495ry5rscpy4x')
,UPPER('0x1B247755FEcDe192587fd92751D88235833420E7')
,UPPER('GAHO7ROH62UG6ZE3LW6OG4EQQ6D2S3CPSFVTODDTC6QY6RMEHCCVWLXX')
,UPPER('rPxBxMcm9T4DBqb9o7ZXKv4xvbRxGs85La')
,UPPER('bitcoincash:qzccwn8g0cyzl4d07w0p3ct2zktc4nsm7qghxc33kl')
,UPPER('ltc1qj6ax755cej8hcz6padp7xk4p05w025qfarf0pj'))