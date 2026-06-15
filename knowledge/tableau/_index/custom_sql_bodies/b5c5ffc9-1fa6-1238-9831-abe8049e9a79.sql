SELECT
  tr.GCID
  , tr.RealCID
  , tr.CryptoId
  , tr.CryptoName
  , tr.TranStatus
  , tr.TranDate
  , tr.ActionDirection
  , tr.Amount
  , tr.AmountUSD
  , tr.SenderAddress
  , tr.ReciverAddress
  , tr.BlockchainTransactionId
  , tr.TransactionType
  , tr.TranDateTime
  , tr.LastStatusUpdateOccurred
  , s.RequestID
  , s.CorrelationId
  , s.RequestType
  , s.FiatAmount
  , s.FiatRateCalculationTime
  , s.FiatConversionTime
  , s.TransactionTravelRuleInformationId
  , s.TravelRuleStatusId
  , s.ProofDetails
  , s.ApprovalReason
  , s.ApprovalType
  , s.ProofType
  , s.ProofAttestation
  , s.ProofConfirmed
  , s.ProofStatus
  , s.TravelRuleStatus
  , s.[Travel Rule Status Time]
  , s.IsWhiteListed
  , s.WhiteListedTime
  , s.WhiteListedProofType
,tr.TranID
 ,tr.Country , tr.Regulation
  , CASE
      WHEN s.CorrelationId IS NOT NULL THEN 'TravelRule'
      WHEN tr.TransactionType IN ('Redeem', 'ConversionToFiat') THEN 'InternalActivity'
      WHEN s.CorrelationId IS NULL AND tr.TranDateTime < '2025-11-06' THEN 'Befor05.11'
      WHEN s.CorrelationId IS NULL AND tr.CryptoId = 4 AND tr.AmountUSD <= 6 THEN 'UnderLimit'
      WHEN s.CorrelationId IS NULL AND tr.CryptoId <> 4 AND tr.AmountUSD <= 2 THEN 'UnderLimit'
      ELSE 'NA'
    END AS TravelRuleExist
  , s.BeneficiaryAddressType
FROM (
  SELECT
    eft.GCID
    , eft.RealCID
    , eft.CryptoId
    , eft.CryptoName
    , eft.TranStatus
    , eft.TranDate
    , eft.ActionTypeName AS ActionDirection
    , eft.Amount
    , eft.AmountUSD
    , eft.SenderAddress
    , eft.ReciverAddress
    , eft.BlockchainTransactionId
    , CASE
        WHEN eft.ActionTypeName = 'Sent' THEN eft.TransactionType
        WHEN eft.ActionTypeName = 'Recive' THEN (CASE WHEN eft.IsRedeem = 1 THEN 'Redeem' ELSE eft.ReceivedTransactionType END)
        ELSE NULL
      END AS TransactionType
    , eft.TranDateTime
    , eft.DateOccured
    , eft.LastStatusUpdateOccurred
    , eft.ActionTypeID
    , eft.TranID
 ,dc.Name Country , dr.Name Regulation
  FROM EXW_dbo.EXW_FactTransactions AS eft
  INNER JOIN EXW_dbo.EXW_WalletEntity AS ewe
    ON eft.GCID = ewe.GCID
   AND eft.TranDateID = ewe.DateID
   AND ewe.WalletEntity = 'eToroME'
  LEFT JOIN EXW_dbo.EXW_TestUsers AS etu
    ON eft.GCID = etu.GCID
LEFT JOIN DWH_dbo.Dim_Country dc 
ON ewe.CountryID = dc.CountryID
LEFT JOIN DWH_dbo.Dim_Regulation dr
ON dc.RegulationID = ewe.RegulationID
  WHERE etu.GCID IS NULL
    AND eft.TranStatusID = 2
    AND eft.GCID > 0
    AND (eft.ActionTypeID <> 2 OR eft.AmountUSD > 0.0001)
   AND eft.TranDateID		
BETWEEN 
    CAST(CONVERT(varchar(8), CAST( <[Parameters].[Start Date Transaction (copy)_257831135502532609]> AS DATE), 112) AS int) 
    AND 
    CAST(CONVERT(varchar(8), CAST( <[Parameters].[End Date Transaction (copy)_257831135502512128]> AS DATE), 112) AS int)
) AS tr
LEFT JOIN #TravelRuleRequestPrep AS s
  ON tr.TranID = s.TranID
 AND s.ActionTypeID = tr.ActionTypeID