SELECT ab.date
  ,ab.account_name
  ,ab.coin
  ,ab.balance
  ,ab.EOD_Bid_Price
  ,mp.company
  ,mp.account_mapping_for_cy_finance
  ,mp.independent_check
  ,mp.real_nostro
  ,mp.regulation
  ,mp.storage
  ,mp.wallet_name
FROM
(SELECT 
  b.date,
  b.account_name,
  b.coin,
  b.balance,
  cp.EOD_Bid_Price
FROM 
(  
  SELECT 
    a.date,
    a.account_name,
    a.coin,
    SUM(a.balance) AS balance
  FROM (

    /* 1) Daily snapshots */
    SELECT
      CAST(bronze.Date AS DATE)              AS date,
      bronze.AccountName                     AS account_name,
      bronze.Coin                            AS coin,
      bronze.SnapshotBalance                  AS balance
    FROM finance.bronze_cwadb_dbo_vaccountsummary AS bronze

    UNION ALL

    /* 2) Gold Lukka */
    SELECT
      CAST(gold.etr_ymd AS DATE)             AS date,
      gold.`Column`                           AS account_name,   -- literal column name "Column"
      gold.Coin_Asset_Code                   AS coin,
      gold.Balance_Amount                 AS balance
    FROM main.general.gold_lukka_flat_custom_report AS gold

    UNION ALL

    /* 3) Monthly sheet row (prev EOM) repeated for each day of current month (through today) */
    SELECT
      CAST(ii.date AS DATE)                                  AS date,
      ii.account_name                        AS account_name,
      ii.coin                                AS coin,
      ii.amount                                AS balance
    FROM finance.bronze_fivetran_google_sheets_monthly_adjustemt_for_finance_inventory AS ii
  ) a
 group by a.date,
    a.account_name,
    a.coin
) AS b
LEFT JOIN 
(
SELECT TRIM(SUBSTRING_INDEX(di.Name, '/', 1)) as base_currency
    ,DATEADD(DAY,1,fcpws.OccurredDate) AS etr_ymd
    ,fcpws.BidSpreaded AS EOD_Bid_Price
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit fcpws
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di on fcpws.InstrumentID = di.InstrumentID
WHERE di.SellCurrency= 'USD'
) AS cp
  ON cp.base_currency = b.coin
 AND cp.etr_ymd = b.date
)ab
LEFT JOIN main.finance.bronze_fivetran_google_sheets_master_account_mapping mp on ab.account_name = mp.account_name