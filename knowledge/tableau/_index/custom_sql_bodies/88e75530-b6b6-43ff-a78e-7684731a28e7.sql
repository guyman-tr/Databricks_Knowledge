SELECT mft.RealCID AS 'CID'
      ,mft.TransactionID
      ,CASE WHEN mft.TransactionTypeId = 8 THEN 'IBAN to External'
            WHEN mft.TransactionTypeId = 7 THEN 'External to IBAN'
            WHEN mft.TransactionTypeId = 6 THEN 'IBAN to Trading Platform'
            WHEN mft.TransactionTypeId = 5 THEN 'Trading Platform to IBAN'
            WHEN mft.TransactionTypeId IN (1,2,3,4) THEN 'Card Use' 
            ELSE mft.TransactionType END 'TransactionNarrative'
	 ,CAST(mft.TransactionLocalTime AS DATE) AS 'TransactionLocalDate'
     ,CAST(mft.StatusModificationTime AS DATE) AS 'StatusModificationDate'
	 ,mft.TransactionStatus
     ,mft.HolderCurrency
     ,mft.HolderAmount AS 'Amount_HolderCurrency'
FROM eMoney.dbo.eMoney_Fact_Transactions mft WITH(NOLOCK)
WHERE mft.RealCID = <[Parameters].[RealCID Parameter]>
      AND mft.DateID >= <[Parameters].[Parameter 1]>
      AND mft.DateID <= <[Parameters].[Parameter 2]>