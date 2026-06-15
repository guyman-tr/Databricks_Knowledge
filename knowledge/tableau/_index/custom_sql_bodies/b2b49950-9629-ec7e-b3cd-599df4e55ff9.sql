-- C2P
SELECT
  ecfee.EOM
  , ecfee.TxNumber
  , ecfee.UsdAmount
  , ecfee.Users
  , monthly.TotalUsersPerMonth
  , ecfee.CryptoAmount
  , ecfee.Crypto
  , ecfee.Activity
FROM (
  SELECT
    EOMONTH(LastModificationDate) AS EOM
    , count(CorrelationID) AS TxNumber
    , sum(FactActionCompensationAmountUSD) AS UsdAmount
    , COUNT(DISTINCT GCID) AS Users
    , sum(SentAmount) AS CryptoAmount
    , Crypto
    , 'C2P' AS Activity
  FROM EXW_dbo.EXW_C2P_E2E
  WHERE 1 = 1
    AND LastModificationDate >= DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
    AND ConversionCycle = 'Full Cycle'
  GROUP BY EOMONTH(LastModificationDate), Crypto
) ecfee
LEFT JOIN (
  SELECT
    EOMONTH(LastModificationDate) AS EOM
    , COUNT(DISTINCT GCID) AS TotalUsersPerMonth
  FROM EXW_dbo.EXW_C2P_E2E
  WHERE 1 = 1
    AND LastModificationDate >= DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
    AND ConversionCycle = 'Full Cycle'
  GROUP BY EOMONTH(LastModificationDate)
) monthly ON ecfee.EOM = monthly.EOM

UNION ALL

-- C2F
SELECT
  ecfee.EOM
  , ecfee.TxNumber
  , ecfee.UsdAmount
  , ecfee.Users
  , monthly.TotalUsersPerMonth
  , ecfee.CryptoAmount
  , ecfee.Crypto
  , ecfee.Activity
FROM (
  SELECT
    EOMONTH(LastModificationDate) AS EOM
    , count(C2FCorrelationID) AS TxNumber
    , sum(UsdAmount) AS UsdAmount
    , COUNT(DISTINCT GCID) AS Users
    , sum(SentAmount) AS CryptoAmount
    , Crypto
    , 'C2F' AS Activity
  FROM EXW_dbo.EXW_C2F_E2E
  WHERE 1 = 1
    AND LastModificationDate >= DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
    AND ConversionCycle = 'Full Cycle'
  GROUP BY EOMONTH(LastModificationDate), Crypto
) ecfee
LEFT JOIN (
  SELECT
    EOMONTH(LastModificationDate) AS EOM
    , COUNT(DISTINCT GCID) AS TotalUsersPerMonth
  FROM EXW_dbo.EXW_C2F_E2E
  WHERE 1 = 1
    AND LastModificationDate >= DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
    AND ConversionCycle = 'Full Cycle'
  GROUP BY EOMONTH(LastModificationDate)
) monthly ON ecfee.EOM = monthly.EOM

UNION ALL

-- CryptoIN
SELECT
  eft.EOM
  , eft.TxNumber
  , eft.UsdAmount
  , eft.Users
  , monthly.TotalUsersPerMonth
  , eft.CryptoAmount
  , eft.Crypto
  , eft.Activity
FROM (
  SELECT
    EOMONTH(eft.TranDate) AS EOM
    , count(eft.TranID) AS TxNumber
    , sum(eft.AmountUSD) AS UsdAmount
    , COUNT(DISTINCT eft.GCID) AS Users
    , sum(eft.Amount) AS CryptoAmount
    , eft.CryptoName AS Crypto
    , 'CryptoIN' AS Activity
  FROM EXW_dbo.EXW_FactTransactions eft
  JOIN EXW_dbo.EXW_DimUser edu ON eft.GCID = edu.GCID
  LEFT JOIN (
    SELECT CASE WHEN NormalizedAddress = Address THEN Address ELSE NormalizedAddress END AS Address
    FROM EXW_Wallet.WalletAddresses
  ) a ON eft.SenderAddress = a.Address
  WHERE 1 = 1
    AND edu.IsTestAccount = 0
    AND eft.AmountUSD > 0.1
    AND eft.ActionTypeID = 2
    AND eft.TranStatusID = 2
    AND eft.IsRedeem = 0
    AND eft.GCID > 0
    AND eft.TranDate >= DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
    AND a.Address IS NULL
  GROUP BY EOMONTH(eft.TranDate), eft.CryptoName
) eft
LEFT JOIN (
  SELECT
    EOMONTH(eft.TranDate) AS EOM
    , COUNT(DISTINCT eft.GCID) AS TotalUsersPerMonth
  FROM EXW_dbo.EXW_FactTransactions eft
  JOIN EXW_dbo.EXW_DimUser edu ON eft.GCID = edu.GCID
  LEFT JOIN (
    SELECT CASE WHEN NormalizedAddress = Address THEN Address ELSE NormalizedAddress END AS Address
    FROM EXW_Wallet.WalletAddresses
  ) a ON eft.SenderAddress = a.Address
  WHERE 1 = 1
    AND edu.IsTestAccount = 0
    AND eft.AmountUSD > 0.1
    AND eft.ActionTypeID = 2
    AND eft.TranStatusID = 2
    AND eft.IsRedeem = 0
    AND eft.GCID > 0
    AND eft.TranDate >= DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
    AND a.Address IS NULL
  GROUP BY EOMONTH(eft.TranDate)
) monthly ON eft.EOM = monthly.EOM

UNION ALL

-- CryptoOut
SELECT
  eft.EOM
  , eft.TxNumber
  , eft.UsdAmount
  , eft.Users
  , monthly.TotalUsersPerMonth
  , eft.CryptoAmount
  , eft.Crypto
  , eft.Activity
FROM (
  SELECT
    EOMONTH(eft.TranDate) AS EOM
    , count(eft.TranID) AS TxNumber
    , sum(eft.AmountUSD) AS UsdAmount
    , COUNT(DISTINCT eft.GCID) AS Users
    , sum(eft.Amount) AS CryptoAmount
    , eft.CryptoName AS Crypto
    , 'CryptoOut' AS Activity
  FROM EXW_dbo.EXW_FactTransactions eft
  JOIN EXW_dbo.EXW_DimUser edu ON eft.GCID = edu.GCID
  LEFT JOIN (
    SELECT CASE WHEN NormalizedAddress = Address THEN Address ELSE NormalizedAddress END AS Address
    FROM EXW_Wallet.WalletAddresses
  ) a ON eft.ReciverAddress = a.Address
  WHERE 1 = 1
    AND edu.IsTestAccount = 0
    AND eft.ActionTypeID = 1
    AND eft.TranStatusID = 2
    AND eft.TransactionTypeID = 1
    AND eft.GCID > 0
    AND eft.TranDate >= DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
    AND a.Address IS NULL
  GROUP BY EOMONTH(eft.TranDate), eft.CryptoName
) eft
LEFT JOIN (
  SELECT
    EOMONTH(eft.TranDate) AS EOM
    , COUNT(DISTINCT eft.GCID) AS TotalUsersPerMonth
  FROM EXW_dbo.EXW_FactTransactions eft
  JOIN EXW_dbo.EXW_DimUser edu ON eft.GCID = edu.GCID
  LEFT JOIN (
    SELECT CASE WHEN NormalizedAddress = Address THEN Address ELSE NormalizedAddress END AS Address
    FROM EXW_Wallet.WalletAddresses
  ) a ON eft.ReciverAddress = a.Address
  WHERE 1 = 1
    AND edu.IsTestAccount = 0
    AND eft.ActionTypeID = 1
    AND eft.TranStatusID = 2
    AND eft.TransactionTypeID = 1
    AND eft.GCID > 0
    AND eft.TranDate >= DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
    AND a.Address IS NULL
  GROUP BY EOMONTH(eft.TranDate)
) monthly ON eft.EOM = monthly.EOM

UNION ALL

-- Redeem
SELECT
  err.EOM
  , err.TxNumber
  , err.UsdAmount
  , err.Users
  , monthly.TotalUsersPerMonth
  , err.CryptoAmount
  , err.Crypto
  , err.Activity
FROM (
  SELECT
    EOMONTH([etoro - ModificationDate]) AS EOM
    , count(PositionID) AS TxNumber
    , sum([eToro - AmountOnCloseUSD]) AS UsdAmount
    , COUNT(DISTINCT [Wallet - RequestingGCID]) AS Users
    , sum([Wallet - SentAmount]) AS CryptoAmount
    , CryptoName AS Crypto
    , 'Redeem' AS Activity
  FROM EXW_dbo.EXW_RedeemReconciliation
  WHERE [etoro - ModificationDate] >= DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
    AND EntryAppears = 'BothSidesEntry'
    AND [etoro - RedeemStatus] = 'TransactionDone'
  GROUP BY EOMONTH([etoro - ModificationDate]), CryptoName
) err
LEFT JOIN (
  SELECT
    EOMONTH([etoro - ModificationDate]) AS EOM
    , COUNT(DISTINCT [Wallet - RequestingGCID]) AS TotalUsersPerMonth
  FROM EXW_dbo.EXW_RedeemReconciliation
  WHERE [etoro - ModificationDate] >= DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
    AND EntryAppears = 'BothSidesEntry'
    AND [etoro - RedeemStatus] = 'TransactionDone'
  GROUP BY EOMONTH([etoro - ModificationDate])
) monthly ON err.EOM = monthly.EOM

-- ORDER BY Activity, EOM, Crypto