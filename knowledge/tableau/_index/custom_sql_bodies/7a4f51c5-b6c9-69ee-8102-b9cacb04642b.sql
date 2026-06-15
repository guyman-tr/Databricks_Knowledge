SELECT 
    a.*, 
    b.RegisteredReal,
    c.AccountCreateDate,

    -- 1. Seniority Fields
    YEAR(b.RegisteredReal) AS TP_seniority,
    YEAR(c.AccountCreateDate) AS IBAN_seniority,

    -- 2. Wallet Income Flag
    CASE 
        WHEN d.RealCID IS NOT NULL THEN 1 
        ELSE 0 
    END AS IsWalletIncomeWeekBefore,

    -- 3. IBAN Flag
    CASE
        WHEN a.TxTypeID IN (14, 7, 5, 9) THEN 1
        WHEN a.TxTypeID IN (1, 2, 3, 4, 8, 6, 13) THEN 0
        WHEN a.TxTypeID = 8888 THEN 1  -- Close Position
        WHEN a.TxTypeID = 9999 THEN 0  -- Open Position
        ELSE NULL
    END AS IsInIBAN,

    -- 4. Transaction Description with Card and custom handling
    CASE
        WHEN a.TxTypeID IN (1, 2, 3, 4, 13) THEN 'Card'
        WHEN a.TxTypeID = 9999 THEN 'Open Position'
        WHEN a.TxTypeID = 8888 THEN 'Close Position'
        ELSE tx_dict.TransactionType
    END AS TransactionDesc

FROM (
    SELECT
        tx.CID,
        tx.TxTypeID,
        tx.TxStatusModificationDateID AS TxDateID,
        tx.USDAmountApprox
    FROM eMoney_dbo.eMoney_Dim_Transaction tx
    JOIN (
        SELECT 
            CID, 
            MIN(TxStatusModificationTime) AS FirstC2FTime
        FROM eMoney_dbo.eMoney_Dim_Transaction
        WHERE TxTypeID = 14 
            AND TxStatusModificationDateID > 20250301
            AND IsValidETM = 1 
            AND IsTxSettled = 1
        GROUP BY CID
    ) fc ON tx.CID = fc.CID AND tx.TxStatusModificationTime >= fc.FirstC2FTime
    WHERE tx.IsValidETM = 1 
        AND tx.IsTxSettled = 1 
        AND tx.TxStatusModificationDateID > 20250301

    UNION 

    SELECT 
        b.CID,
        9999 AS TxTypeID,
        CAST(CONVERT(VARCHAR(8), b.OpenOccurred, 112) AS INT) AS TxDateID,
        b.Amount
    FROM BI_DB_dbo.External_bi_output_finance_bi_db_positions_opened_from_iban_parquet a 
    JOIN DWH_dbo.Dim_Position b 
        ON a.PositionID = b.PositionID 
    JOIN (
        SELECT 
            CID, 
            MIN(TxStatusModificationTime) AS FirstC2FTime
        FROM eMoney_dbo.eMoney_Dim_Transaction
        WHERE TxTypeID = 14 
            AND TxStatusModificationDateID > 20250301
            AND IsValidETM = 1 
            AND IsTxSettled = 1
        GROUP BY CID
    ) c ON b.CID = c.CID AND b.OpenOccurred >= c.FirstC2FTime
    WHERE b.IsPartialCloseChild = 0 
        AND b.CloseOccurred > CAST('2025-03-01' AS DATETIME)

    UNION 

    SELECT 
        b.CID,
        8888 AS TxTypeID,
        CAST(CONVERT(VARCHAR(8), b.CloseOccurred, 112) AS INT) AS TxDateID,
        b.Amount
    FROM BI_DB_dbo.External_bi_output_finance_bi_db_positions_closed_to_iban_parquet a 
    JOIN DWH_dbo.Dim_Position b 
        ON a.PositionID = b.PositionID 
    JOIN (
        SELECT 
            CID, 
            MIN(TxStatusModificationTime) AS FirstC2FTime
        FROM eMoney_dbo.eMoney_Dim_Transaction
        WHERE TxTypeID = 14 
            AND TxStatusModificationDateID > 20250301
            AND IsValidETM = 1 
            AND IsTxSettled = 1
        GROUP BY CID
    ) c ON b.CID = c.CID AND b.CloseOccurred >= c.FirstC2FTime
    WHERE b.IsPartialCloseChild = 0
        AND b.CloseOccurred > CAST('2025-03-01' AS DATETIME)
) a

JOIN DWH_dbo.Dim_Customer b 
    ON a.CID = b.RealCID 

JOIN eMoney_dbo.eMoney_Dim_Account c 
    ON a.CID = c.CID 

LEFT JOIN (
    SELECT 
        eft.RealCID,
        eft.TranDateID
    FROM EXW_dbo.EXW_FactTransactions eft 
    WHERE eft.GCID > 0
        AND ActionTypeID = 2
        AND eft.IsRedeem = 0
        AND eft.IsConversion = 0
        AND eft.IsPayment = 0
        AND ISNULL(eft.IsFunding, 0) <> 1
        AND ISNULL(eft.ReceivedTransactionTypeID, 99) NOT IN (8, 3, 5, 2, 6)
        AND eft.SenderAddress <> '0x5be786ad38f5846f605a8003550074cdfd4899a1'
        AND CASE WHEN CryptoId = 21 AND AmountUSD <= 0.000001 THEN 1 ELSE 0 END = 0
        AND eft.TranStatusID = 2 
        AND eft.TranDateID > 20250301
) d 
    ON a.CID = d.RealCID  
    AND CONVERT(DATE, CAST(a.TxDateID AS CHAR(8))) 
        BETWEEN CONVERT(DATE, CAST(d.TranDateID AS CHAR(8))) 
        AND DATEADD(DAY, 7, CONVERT(DATE, CAST(d.TranDateID AS CHAR(8))))

LEFT JOIN eMoney_dbo.eMoney_Dictionary_TransactionType tx_dict
    ON a.TxTypeID = tx_dict.TransactionTypeID