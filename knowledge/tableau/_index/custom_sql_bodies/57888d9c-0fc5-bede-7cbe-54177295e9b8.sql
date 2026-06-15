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

SELECT DISTINCT
    t.TxLabel,
    t.ProviderCurrencyBalanceID,
    t.CID
    ,t.ClubTxDate as ClubLevel
    ,t.CountryTxDate as RegCountry
    ,max(a.TxDate) as AlertDate
    ,e.ProviderHolderID as HID
    ,t.TransactionID
    ,t.TxStatus
FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction t
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account e on e.ProviderCurrencyBalanceID = t.ProviderCurrencyBalanceID
JOIN alerts a
    ON t.TxLabel = a.TxLabel
    --AND CAST(t.TxCreatedDate AS DATE) = a.TxDate

WHERE
    t.MoneyMoveDirection = 'MoneyOut'
    AND t.TxLabel <> 'eToro Trading Platform DPT'
    AND t.IsValidCustomer = 1
    AND t.IsValidETM = 1
    AND t.TxCreatedDate >= DATEADD(year, -2, CURRENT_DATE)
    AND a.txlabel is not null
    --AND a.txdate = '2026-03-17'
GROUP BY 
  t.TxLabel,
    t.ProviderCurrencyBalanceID,
    CASE 
        WHEN a.TxLabel IS NOT NULL THEN 1
        ELSE 0
    END ,
    t.CID
    ,t.ClubTxDate
    ,t.CountryTxDate
    ,e.ProviderHolderID
    ,t.TransactionID
    ,t.TxStatus
--ORDER BY Date DESC