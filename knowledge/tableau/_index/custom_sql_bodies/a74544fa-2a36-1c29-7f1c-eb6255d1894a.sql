SELECT 
    CID, 
    GCID, 
    TxType, 
    USDAmountApprox, 
    HolderAmount, 
    HolderCurrencyDesc, 
    TxStatusModificationDate, 
    MoneyMoveDirection, 
    TxStatusModificationTime, MerchantID , TransactionID, HolderCurrencyDesc
FROM 
    main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction
WHERE 
    IsTxSettled = 1 
    AND TxTypeID IN (1, 2, 3, 4, 13)
    -- 1. Hard floor: Don't go before Jan 2026
    AND TxStatusModificationDateID >= 20260101
    -- 2. Dynamic: Look back 365 days from the latest date in the data
    AND TxStatusModificationDate >= (SELECT MAX(TxStatusModificationDate) - INTERVAL 365 DAYS FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction)