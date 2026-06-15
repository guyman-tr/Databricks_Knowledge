SELECT 
frcf.CID ,
    rol.Region,
    frcf.AccountTypeID,
    mda.CurrencyBalanceCreateDate AS eMoney_Created_Date,
        TRY_CAST(CAST(frcf.DateID AS VARCHAR(8)) AS DATE) AS Date_ ,
    
    -- Deposit Fee (Open LC)
    SUM(CASE 
        WHEN frcf.TransactionType = 'Deposit' THEN ISNULL(frcf.ConversionFee, 0) ELSE 0  
    END) AS Amount_Fee_Open_LC,

    -- Withdraw Fee (Close LC)
    SUM(CASE 
        WHEN frcf.TransactionType = 'Withdraw' THEN ISNULL(frcf.ConversionFee, 0) else 0 
    END) AS Amount_Fee_close_LC

FROM BI_DB_dbo.Function_Revenue_ConversionFee(
    20240401,
    CONVERT(INT, CONVERT(VARCHAR(8), GETDATE(), 112)), -- THIS IS THE CORRECTED PART
    1
) frcf

-- Join to Country Rollout
JOIN eMoney_dbo.eMoney_Dim_Country_Rollout rol 
    ON frcf.CountryID = rol.CountryID

LEFT JOIN (
    SELECT * 
    FROM eMoney_dbo.eMoney_Dim_Account 
    WHERE GCID_Unique_Count = 1 AND IsValidETM = 1
) mda 
    ON frcf.CID = mda.CID

-- Filter only IBAN transactions
WHERE frcf.IsIBANTrade = 1

GROUP BY 
    frcf.CID,
    TRY_CAST(CAST(frcf.DateID AS VARCHAR(8)) AS DATE)  ,
    rol.Region,
     frcf.AccountTypeID,
    mda.CurrencyBalanceCreateDate