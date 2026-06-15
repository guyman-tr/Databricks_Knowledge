SELECT  
	   st.BlockchainTransactionId  [Blockchain TransactionID]
	  ,st.WalletId
	  ,st.Occurred [Wallet Sent DateTime]
	  ,st.CorrelationId [Correlation ID]
	  ,st.BlockchainFee
	  ,st.CryptoId [Crypto ID]
	  ,ct.Name Crypto
	  ,c.Id   [Conversion ID]
	  ,c.Gcid GCID
	  ,c.ConversionFeePercentage [Total Fee] 
      ,ctrx.Amount [Crypto Amount]
	  ,esto.ToAddress
	  ,c.Occurred [C2F DateTime]
	  ,dst.Name AS [C2F Status]
	  ,ftx.CryptoToFiatRate [Fiat CryptoToFiat Rate]
	  ,ftx.FiatToUsdRate [Fiat FiatToUsd Rate]
      ,ftx.CryptoToUsdRate [Fiat CryptoToUsd Rate]
      ,ftx.FiatAmount [Fiat Amount ToSend]
	  , ftx.UsdAmount [USD Amount]
      ,ftx.AccountId [Fiat AccountID]
   	  ,sss.HolderAmount [eMoney Holder Amount]
	  ,sss.TransactionOccured [eMoney Status Date Time]
	  ,sss.HolderCurrency  
	 , mc.Currency AS [Fiat Holder Currency]
 
FROM Wallet_Server_WalletDB.WalletDB.Wallet.SentTransactions st  
	JOIN Wallet_Server_WalletDB.WalletDB.Wallet.SentTransactionOutputs esto ON esto.SentTransactionId =st.Id
	JOIN Wallet_Server_WalletDB.WalletDB.Wallet.SentTransactionStatuses ests ON ests.SentTransactionId=esto.SentTransactionId
    LEFT JOIN   [cryptodata_server_WalletConversionDB].[WalletConversionDB].[C2F].[Conversions] c ON st.CorrelationId =c.CorrelationId
    LEFT JOIN   [cryptodata_server_WalletConversionDB].[WalletConversionDB].C2F.CryptoTransactions  ctrx ON ctrx.ConversionId= c.Id
	LEFT JOIN Wallet_Server_WalletDB.WalletDB.Wallet.Requests er  ON st.CorrelationId = er.CorrelationId
    LEFT JOIN  [cryptodata_server_WalletConversionDB].[WalletConversionDB].[C2F].[ConversionStatuses] cst  ON cst.ConversionId =c.Id
    LEFT JOIN  [cryptodata_server_WalletConversionDB].[WalletConversionDB].[Dictionary].[ConversionToFiatStatuses] dst ON dst.Id= cst.StatusId
    LEFT JOIN [cryptodata_server_WalletConversionDB].[WalletConversionDB].[C2F].[FiatTransactions]  ftx ON ftx.[ConversionId] =c.Id
   --LEFT JOIN eMoney.dbo.eMoney_Dim_Transaction mdt ON mdt.ReferenceNumber  = ftx.Details  COLLATE SQL_Latin1_General_CP1_CI_AS
    LEFT JOIN  FiatDwhDB.FiatDwhDB.dbo.FiatTransactionsStatuses  sss ON er.CorrelationId =sss.CorrelationId
   JOIN Wallet_Server_WalletDB.WalletDB.Wallet.CryptoTypes ct ON st.CryptoId =ct.CryptoID
 JOIN eMoney.dbo.eMoney_DictionaryCurrencyISO_Static  mc  ON mc.CurrencyISO=sss.HolderCurrency
   WHERE st.TransactionTypeId =12
  AND ests.StatusId=2
  AND cst.StatusId =3 
  AND sss.TransactionStatusId =2

  AND c.Occurred >getdate()-5