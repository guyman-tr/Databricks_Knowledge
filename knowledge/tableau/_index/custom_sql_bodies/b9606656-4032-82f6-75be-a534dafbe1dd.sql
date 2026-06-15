SELECT
    COALESCE(eccc.Current_Coin_Balance, 0) AS Balance,
    COALESCE(eccc.Current_Coin_Balance, 0) AS BalanceAmountDivAdjustments,
    CASE WHEN COALESCE(eccc.Current_Coin_Balance, 0) * COALESCE(x.EOD_Price, 0) > 10 THEN 'Over 10' ELSE 'Under 10' END AS Indicator,
    COALESCE(eccc.Current_Coin_Balance, 0) * COALESCE(x.EOD_Price, 0) AS CurrentValue,
    <[Parameters].[Parameter 1]> AS CompensationDate,
    COALESCE(x.EOD_Price, 0) AS EOD_Bid_Prce,
    'Close Wallets' AS AccountName,
    'Close Wallets' AS SourceName,
    NULL AS SubAccountName,
    CryptoName as CoinAssetCodeCalc,
    0 AS PendingRewardsAmount,
    eccc.CryptoName,
    eccc.UserWalletAllowance

FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_reimbursementfollowup eccc
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ewe
    ON eccc.GCID = ewe.GCID
    AND CompensationDate = ewe.Date
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ewe2
    ON eccc.GCID = ewe2.GCID
    AND ewe2.Date = (SELECT MAX(Date) FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity)
LEFT JOIN (
    SELECT bdcn.InstrumentName, MAX(bdcn.EOD_Bid_Price) AS EOD_Price, bdcn.Date
    FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop bdcn
    WHERE bdcn.InstrumentName LIKE '%/USD'
      AND bdcn.Date = <[Parameters].[Parameter 1]>
    GROUP BY bdcn.InstrumentName, bdcn.Date
) x
    ON x.InstrumentName = CONCAT(CryptoName, '/USD')
WHERE 1=1
    AND CompensationDate IS NOT NULL
    AND Reimbursement_Coin_Balance > 0
    AND (
        (eccc.Project LIKE 'AML%' AND LOWER(eccc.AMLStatus) IN ('compensated', 'reimbursed', 'completed'))
        OR eccc.Project NOT LIKE 'AML%'
    )
    AND eccc.CompensationDate <= <[Parameters].[Parameter 1]>

UNION ALL

--QA
SELECT * FROM (
    SELECT
        SUM(COALESCE(efrbn.Balance, 0)) AS Balance,
        SUM(COALESCE(efrbn.Balance, 0)) AS BalanceAmountDivAdjustments,
        NULL AS Indicator,
        SUM(efrbn.BalanceUSD) AS CurrentValue,
        <[Parameters].[Parameter 1]> AS CompensationDate,
        NULL AS EOD_Bid_Prce,
        'QA' AS AccountName,
        'QA' AS SourceName,
        NULL AS SubAccountName,
        NULL AS CoinAssetCodeCalc,
        0 AS PendingRewardsAmount,
        efrbn.CryptoName,
        NULL AS UserWalletAllowance
    FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew efrbn
    JOIN main.wallet.bronze_walletdb_wallet_cryptotypes ect
        ON efrbn.CryptoID = ect.CryptoID
        AND BalanceDate = <[Parameters].[Parameter 1]>
    WHERE efrbn.IsTestAccount = 1
    GROUP BY efrbn.CryptoName
    ORDER BY CurrentValue DESC
    LIMIT 30
) v

UNION ALL

--Lukka Reports (Flat, Pending, Pending Rewards)
SELECT
    c.balance AS Balance,
    NULL AS BalanceAmountDivAdjustments,
    NULL AS Indicator,
    c.balance AS CurrentValue,
    c.date AS CompensationDate,
    NULL AS EOD_Bid_Prce,
    c.account_name AS AccountName,
    c.Source_Name AS SourceName,
    c.sub_account_name AS SubAccountName,
    c.coin AS CoinAssetCodeCalc,
    c.Pending_Rewards_Amount AS PendingRewardsAmount,
    NULL AS CryptoName,
    NULL AS UserWalletAllowance
FROM (
    SELECT
        CAST(gold.etr_ymd AS DATE) AS date,
        'Flat Report' AS Source_Name,
        gold.`Column` AS account_name,
        gold.Account AS sub_account_name,
        gold.Coin_Asset_Code AS coin,
        gold.Balance_Amount AS balance,
        CAST(NULL AS DOUBLE) AS Pending_Rewards_Amount
    FROM main.general.gold_lukka_flat_custom_report AS gold
    WHERE gold.etr_ymd = <[Parameters].[Parameter 1]>

    UNION ALL

    SELECT
        CAST(ii.etr_ymd AS DATE) AS date,
        'Pending Report' AS Source_Name,
        ii.Account_Name AS account_name,
        ii.Sub_Account_Name AS sub_account_name,
        ii.Base_Asset_Code AS coin,
        CAST(REPLACE(ii.Base_Amount, ',', '') AS DOUBLE) AS balance,
        CAST(NULL AS DOUBLE) AS Pending_Rewards_Amount
    FROM main.general.gold_lukka_pending_tr_transfers_custom_report AS ii
    WHERE ii.etr_ymd = <[Parameters].[Parameter 1]>

    UNION ALL

    SELECT
        CAST(pr.etr_ymd AS DATE) AS date,
        'Pending Rewards' AS Source_Name,
        pr.Account_Name AS account_name,
        pr.Sub_Account_Name AS sub_account_name,
        pr.Asset_Code AS coin,
        0 AS balance,
        CAST(REPLACE(pr.Pending_Rewards_Amount, ',', '') AS DOUBLE) AS Pending_Rewards_Amount
    FROM main.general.gold_lukka_latest_snapshot_with_pending_rewards AS pr
    WHERE pr.etr_ymd = <[Parameters].[Parameter 1]>
) c

UNION ALL

--Hyperliquid Spot Balances
SELECT
    hl.total AS Balance,
    NULL AS BalanceAmountDivAdjustments,
    NULL AS Indicator,
    hl.total AS CurrentValue,
    hl.snapshot_date AS CompensationDate,
    NULL AS EOD_Bid_Prce,
    'Hyperliquid' AS AccountName,
    'Hyperliquid Spot' AS SourceName,
    hl.wallet_address AS SubAccountName,
    hl.coin AS CoinAssetCodeCalc,
    0 AS PendingRewardsAmount,
    hl.coin AS CryptoName,
    NULL AS UserWalletAllowance
FROM main.finance.hyperliquid_spot_balances hl
WHERE hl.snapshot_date = <[Parameters].[Parameter 1]>