SELECT
    a.date                                 AS Date,
    a.coin                                 AS Coin,
    COALESCE(r.Real, 0)                    AS Real,
    a.real_nostro                          AS real_nostro,
    (a.Balance * a.EOD_Bid_Price)          AS Value_USD,   -- [Balance] × [EOD_Bid_Price]
    a.Balance                              AS Balance,
    a.EOD_Bid_Price                        AS EOD_Bid_Price
FROM
(
    /* ===== Accounts + Price, aggregated to date × coin × real_nostro ===== */
    SELECT
        agg.date,
        agg.coin,
        COALESCE(mp.real_nostro, 0)            AS real_nostro,
        SUM(agg.balance)                       AS Balance,
        MAX(cp.EOD_Bid_Price)                  AS EOD_Bid_Price
    FROM
    (
        /* union of all balance sources, then aggregate per date×account×coin */
        SELECT
            b.date,
            b.account_name,
            b.coin,
            SUM(b.balance) AS balance
        FROM
        (
            /* 1) Daily snapshots */
            SELECT
                CAST(bronze.Date AS DATE)          AS date,
                bronze.AccountName                 AS account_name,
                bronze.Coin                        AS coin,
                bronze.SnapshotBalance             AS balance
            FROM finance.bronze_cwadb_dbo_vaccountsummary AS bronze

            UNION ALL
            /* 2) Gold Lukka */
            SELECT
                CAST(gold.etr_ymd AS DATE)         AS date,
                gold.`Column`                      AS account_name,   -- literal column named "Column"
                gold.Coin_Asset_Code               AS coin,
                gold.Balance_Amount                AS balance
            FROM main.general.gold_lukka_flat_custom_report AS gold

            UNION ALL
            /* 3) Monthly sheet row repeated for each day of current month */
            SELECT
                CAST(ii.date AS DATE)              AS date,
                ii.account_name                    AS account_name,
                ii.coin                            AS coin,
                ii.amount                          AS balance
            FROM finance.bronze_fivetran_google_sheets_monthly_adjustemt_for_finance_inventory AS ii
        ) b
        GROUP BY b.date, b.account_name, b.coin
    ) agg
    LEFT JOIN
    (
        /* EOD price per base currency (left side of 'AAA/BBB') for USD quotes */
        SELECT
            TRIM(SUBSTRING_INDEX(di.Name, '/', 1))     AS base_currency,
            date_add(fcpws.OccurredDate, 1)            AS etr_ymd,
            fcpws.BidSpreaded                          AS EOD_Bid_Price
        FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit fcpws
        JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
          ON fcpws.InstrumentID = di.InstrumentID
        WHERE di.SellCurrency = 'USD'
    ) cp
      ON cp.base_currency = agg.coin
     AND cp.etr_ymd       = agg.date
    LEFT JOIN main.finance.bronze_fivetran_google_sheets_master_account_mapping mp
      ON agg.account_name = mp.account_name
    GROUP BY agg.date, agg.coin, COALESCE(mp.real_nostro, 0)
) a
LEFT JOIN
(
    /* ===== Real (on-chain units) from crypto NOP table, per date × coin ===== */
    SELECT
        CAST(bdcn.date AS DATE)         AS date,
        bdcn.BuyCurrency                AS coin,
        SUM(bdcn.Real_Units)            AS Real
    FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop bdcn
    WHERE bdcn.IsCreditReportValidCB = 1
    GROUP BY CAST(bdcn.date AS DATE), bdcn.BuyCurrency
) r
  ON r.date = a.date
 AND r.coin = a.coin
/* optional filters */
-- WHERE a.date = DATE '2025-11-13'
--   AND a.coin = 'BTC'
-- ORDER BY a.real_nostro DESC;