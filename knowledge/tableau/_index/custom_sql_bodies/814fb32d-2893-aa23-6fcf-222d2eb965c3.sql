-- Databricks (no CTE, Tableau-friendly). First part as subselect; EOM via last_day(cast(... AS DATE)).
SELECT DISTINCT
    sub.ProviderAccountID
    , sub.MerchantNumber
    , sub.Merchant
    , sub.MerchantName
    , sub.Mcc
    , sub.TransactionCode
    , sub.TransactionCodeDescription
    , sub.HolderAmount
    , sub.HolderCurrency
    , sub.Action
    , sub.TransLink
    , sub.ParentTransactionId
    , sub.TraceId
    , sub.TransactionDateTime
    , sub.TxStatusModificationDate
    , sub.EOM
    , sub.DateID
    , sub.TxType
    , sub.TxTypeID
    , sub.CID
    , sub.GCID
    , sub.HolderId
    , sub.AccountID
    , sub.ProviderTransactionID
    , sub.TransactionId
    , sub.IsValidETM
    , sub.IsExcluded
    , SUM(CASE WHEN sub.IsExcluded = 'IncludedTx' THEN sub.HolderAmount ELSE 0 END)
        OVER (PARTITION BY sub.ProviderAccountID ORDER BY sub.EOM RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS NetLT
    , SUM(CASE WHEN sub.IsExcluded = 'IncludedTx' THEN sub.HolderAmount ELSE 0 END)
        OVER (PARTITION BY sub.ProviderAccountID ORDER BY sub.EOM RANGE BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS NetLT_PrevMonth
    , sub.PrevEOM
FROM (
    SELECT
        st.AccountId AS ProviderAccountID
        , st.MerchantNumber
        , st.Merchant
        , st.MerchantName
        , st.Mcc
        , st.TransactionCode
        , st.TransactionCodeDescription
        , st.HolderAmount
        , st.HolderCurrencyAlpha AS HolderCurrency
        , st.Action
        , st.TransLink
        , st.ParentTransactionId
        , st.TraceId
        , st.TransactionDateTime
        , dt.TxStatusModificationDate
        , last_day(cast(dt.TxStatusModificationDate AS DATE)) AS EOM
        , last_day(add_months(last_day(cast(dt.TxStatusModificationDate AS DATE)), -1)) AS PrevEOM
        , st.DateID
        , dt.TxType
        , dt.TxTypeID
        , dt.CID
        , dt.GCID
        , st.HolderId
        , dt.AccountID
        , dt.ProviderTransactionID
        , dt.TransactionId
        , dt.IsValidETM
        , CASE
            WHEN st.Mcc IN (
              4812,4813,4814,4816,4821,4829,4899,4900,
                5122,5169,5933,5960,5962,5966,5967,5968,
                6010,6012,6051,6211,6540,
                7273,7299,7800,7801,7802,7994,7995,
                8999,
                9034,9211,9222,9223,9311,9399,9401,9402,9405,
                9700,9701,9702,9751,9752,9754,9950
            ) THEN 'ExcludedMCC'
            WHEN dt.TxTypeID IN (4, 13) THEN 'ExcludedTxType'
            ELSE 'IncludedTx'
        END AS IsExcluded
    FROM bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions st
    JOIN main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction dt
        ON dt.ProviderTransactionID = st.TransactionId
    WHERE dt.IsTxSettled = 1
      AND dt.IsValidETM = 1
      AND dt.CID = CAST(<[Parameters].[Parameter 1]> AS INT)
) sub