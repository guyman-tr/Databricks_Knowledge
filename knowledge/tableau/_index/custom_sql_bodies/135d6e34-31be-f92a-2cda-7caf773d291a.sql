SELECT 
			eft.GCID
		 ,eft.RealCID
		 ,eft.CryptoId
		 ,eft.CryptoName
		 ,eft.WalletID
		 ,eft.TranID
		 ,eft.TranStatusID
		 ,eft.TranStatus
		 ,eft.TranDate
		 ,eft.TranDateID
		 ,eft.Amount
		 ,eft.EtoroFees
		 ,eft.ProviderFees
		 ,eft.ActionTypeID
		 ,eft.ActionTypeName
		 ,eft.AmountUSD
		 ,eft.SenderAddress
		 ,eft.ReciverAddress
		 ,eft.BlockchainTransactionId
		 ,eft.TransactionTypeID
		 ,eft.TransactionType
		 ,eft.Occurred
		 ,eft.TranDateTime
		 ,eft.DateOccured
		 ,eft.LastStatusUpdateOccurred
		 ,so.SourceId
		 ,so.SourceIdType
		 ,s.CorrelationId
		 ,strx.Id
		 ,strx.ExternalStakingAddress
		 ,strx.StakingId
		 ,strx.EtoroFee
		 ,strx.BlockchainEstFee
		 , edu.IsTestAccount
		 , edu.Club
		 , edu.Country
		 , edu.Regulation
		 FROM EXW_FactTransactions eft 
	  JOIN         ETL_SentTransactions   st (NOLOCK) ON st.Id= eft.TranID AND eft.ActionTypeID=1
        JOIN ETL_SentTransactionOutputs so (NOLOCK) ON so.SentTransactionId = st.Id          AND so.IsEtoroFee = 0
        JOIN ETL_StakingStaking s (NOLOCK) ON s.CorrelationId = st.CorrelationId
        JOIN ETL_StakingStakingTransactions strx  (NOLOCK) ON strx.StakingId = s.Id
		JOIN EXW_DimUser edu ON eft.GCID = edu.GCID
    WHERE st.TransactionTypeId = 9