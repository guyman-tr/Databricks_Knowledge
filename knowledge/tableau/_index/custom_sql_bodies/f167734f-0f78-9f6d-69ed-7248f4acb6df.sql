WITH base AS (
    SELECT
        t.TxLabel,
        CAST(t.TxCreatedDate AS DATE) AS TxDate,
        COUNT(t.TransactionID) AS totaltrx,
        COUNT(DISTINCT t.ProviderCurrencyBalanceID) AS NumOfUser
    FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction t
    WHERE
        t.MoneyMoveDirection = 'MoneyOut'
        AND t.TxLabel <> 'eToro Trading Platform DPT'
        AND t.IsValidCustomer = 1
        AND t.IsValidETM = 1
    GROUP BY
        t.TxLabel,
        CAST(t.TxCreatedDate AS DATE)
),

calc AS (
    SELECT
        TxLabel,
        TxDate,
        totaltrx,
        NumOfUser,

        AVG(totaltrx) OVER (
            PARTITION BY TxLabel
            ORDER BY TxDate
            ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
        ) AS avg_last7
    FROM base
),

alerts AS (
    SELECT
        TxLabel,
        TxDate
    FROM calc
    WHERE
        totaltrx > 10
        AND COALESCE(avg_last7,0) = 0
        AND NumOfUser > 1
)

SELECT
    t.TxLabel,
    t.HolderCurrencyDesc,
    t.TxStatus,
    CAST(t.TxCreatedDate AS DATE) AS Date,

    COUNT(DISTINCT t.ProviderCurrencyBalanceID) AS DistinctUsers,
    COUNT(t.TransactionID) AS TotalTransactions,
    SUM(ABS(t.HolderAmount)) AS TotalAmount,
    SUM(ABS(t.USDAmountApprox)) AS TotalUSDAmount,

    SUM(CASE WHEN t.TxStatus = 'Settled' THEN ABS(t.HolderAmount) ELSE 0 END) AS SettledAmount,
    SUM(CASE WHEN t.TxStatus = 'Settled' THEN ABS(t.USDAmountApprox) ELSE 0 END) AS SettledUSDAmount,

    COUNT(DISTINCT CASE WHEN t.TxStatus = 'Settled' THEN t.ProviderCurrencyBalanceID END) AS DistinctSettledUsers,
    COUNT( CASE WHEN t.TxStatus = 'Settled' THEN t.TransactionID END) AS DistinctSettledTransactions,
    CASE 
        WHEN a.TxLabel IS NOT NULL THEN 1
        ELSE 0
    END AS AlertTriggered,max(a.TxDate) as AlertDate

FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction t

LEFT JOIN alerts a
    ON t.TxLabel = a.TxLabel
    --AND CAST(t.TxCreatedDate AS DATE) = a.TxDate

WHERE
    t.MoneyMoveDirection = 'MoneyOut'
    AND t.TxLabel <> 'eToro Trading Platform DPT'
    AND t.IsValidCustomer = 1
    AND t.IsValidETM = 1
    AND t.TxCreatedDate >= DATEADD(year, -2, CURRENT_DATE)
    --and t.TxLabel like 'AMZN Mktp DE AMZN.COM/BILLLU%'
GROUP BY
    t.TxLabel,
    t.HolderCurrencyDesc,
    t.TxStatus,
    CAST(t.TxCreatedDate AS DATE),
    CASE WHEN a.TxLabel IS NOT NULL THEN 1 ELSE 0 END

ORDER BY TotalTransactions