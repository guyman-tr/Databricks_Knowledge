WITH aum_raw AS (
  SELECT
      Portfolio_Id,
      CAST(etr_ymd AS DATE) AS etr_ymd,
      NULLIF(TRIM(Product), '') AS Product_NN,
      NULLIF(TRIM(CAST(Portfolio_Model_Id AS STRING)), '') AS Portfolio_Model_Id_NN,  -- ADDED
      SourceFile,
      CASE
        WHEN REGEXP_EXTRACT(SourceFile, '(\\d{8}T\\d{4})', 1) IS NOT NULL
          THEN TO_TIMESTAMP(
                 REPLACE(REGEXP_EXTRACT(SourceFile, '(\\d{8}T\\d{4})', 1), 'T', ''),
                 'yyyyMMddHHmm'
               )
        ELSE NULL
      END AS sf_ts
  FROM main.money_farm.silver_moneyfarm_etoro_mf_aum
),

/* Dedupe daily snapshots per (Portfolio_Id, etr_ymd) */
aum_dedup AS (
  SELECT *
  FROM (
    SELECT
      r.*,
      ROW_NUMBER() OVER (
        PARTITION BY r.Portfolio_Id, r.etr_ymd
        ORDER BY
          CASE WHEN r.SourceFile IS NOT NULL THEN 1 ELSE 0 END DESC,
          r.sf_ts DESC NULLS LAST
      ) AS rn
    FROM aum_raw r
  ) x
  WHERE rn = 1
),

/* Transactions */
txns AS (
  SELECT
    mftr.*,
    CAST(TO_TIMESTAMP(mftr.Transaction_Date) AS DATE) AS TransactionDt
  FROM main.bi_output.bi_output_moneyfarm_fact_transactions mftr
  WHERE CAST(TO_TIMESTAMP(mftr.Transaction_Date) AS DATE) >= DATE'2025-10-01'
),

/* Resolve product as-of transaction date (latest non-null snapshot <= txn date) */
txn_with_product AS (
  SELECT *
  FROM (
    SELECT
      t.*,
      a.Product_NN            AS Product_AsOfTxn,
      a.Portfolio_Model_Id_NN AS Model_AsOfTxn,  -- ADDED
      ROW_NUMBER() OVER (
        PARTITION BY t.event_correlation_ID
        ORDER BY a.etr_ymd DESC
      ) AS rn_prod
    FROM txns t
    LEFT JOIN aum_dedup a
      ON a.Portfolio_Id = t.PortfolioID
     AND a.etr_ymd <= t.TransactionDt
     AND a.Product_NN IS NOT NULL
  ) x
  WHERE rn_prod = 1
),

/* User filters (one row per GCID) */
user_filters AS (
  SELECT
    dc.GCID,
    dc.Gender,

    DATE_FORMAT(dc.RegisteredReal, 'yyyy-MM') AS Reg_YearMonth,

    /* Treat 1900-01 (and NULL) as "no FTD available" */
    CASE
      WHEN dc.FirstDepositDate IS NULL THEN NULL
      WHEN DATE_FORMAT(dc.FirstDepositDate, 'yyyy-MM') = '1900-01' THEN NULL
      ELSE DATE_FORMAT(dc.FirstDepositDate, 'yyyy-MM')
    END AS FTD_YearMonth,

    ch.Channel,
    ch.SubChannel,

    CASE
      WHEN dc.BirthDate = DATE'1900-01-02' THEN 'No BirthDate Available'
      WHEN YEAR(dc.BirthDate) >= 1997 THEN 'Gen Z (Born >= 1997)'
      WHEN YEAR(dc.BirthDate) BETWEEN 1981 AND 1996 THEN 'Millennials (Born 1981-1996)'
      WHEN YEAR(dc.BirthDate) BETWEEN 1965 AND 1980 THEN 'Gen X (Born 1965-1980)'
      WHEN YEAR(dc.BirthDate) BETWEEN 1946 AND 1964 THEN 'Boomers (Born 1946-1964)'
      WHEN YEAR(dc.BirthDate) <= 1945 THEN 'Silent Generation (Born <=1945)'
      ELSE 'No BirthDate Available'
    END AS BirthCohort
  FROM main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer dc
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel ch
    ON dc.SubChannelID = ch.SubChannelID
),

/* Add date grains + product grouping + join user filters */
txn_enriched AS (
  SELECT
    t.TransactionDt                                           AS Date,       -- yyyy-MM-dd
    DATE_ADD(t.TransactionDt, 1 - DAYOFWEEK(t.TransactionDt))  AS WeekStart,  -- Monday-start week yyyy-MM-dd
    DATE_FORMAT(t.TransactionDt, 'yyyy-MM')                    AS Month,      -- yyyy-MM
    YEAR(t.TransactionDt)                                      AS Year,       -- yyyy

    /* user filter columns */
    uf.FTD_YearMonth,
    uf.Reg_YearMonth,
    uf.Gender,
    uf.Channel,
    uf.SubChannel,
    uf.BirthCohort,

    CASE
      WHEN LOWER(t.Product_AsOfTxn) = 'isa-cash'
       AND LOWER(COALESCE(t.Model_AsOfTxn, '')) = 'etoro-gb-r0-c1-cash-saving-account-v2'
        THEN 'Cash ISA - V2'
      WHEN LOWER(t.Product_AsOfTxn) = 'isa-cash'           THEN 'Cash ISA'
      WHEN LOWER(t.Product_AsOfTxn) = 'isa-discretionary'  THEN 'Managed ISA'
      WHEN LOWER(t.Product_AsOfTxn) = 'isa-execution-only' THEN 'Stocks and Shares ISA'
      ELSE 'Other Products'
    END AS ProductGroup,

    t.TransactionType,
    TRY_CAST(t.Amount_GBP AS DECIMAL(18,2)) AS Amount_GBP
  FROM txn_with_product t
  LEFT JOIN user_filters uf
    ON uf.GCID = t.GCID
),

/* Aggregate at daily grain (re-aggregate to week/month/year in Tableau as needed) */
daily AS (
  SELECT
    Date,
    WeekStart,
    Month,
    Year,

    FTD_YearMonth,
    Reg_YearMonth,
    Gender,
    Channel,
    SubChannel,
    BirthCohort,

    ProductGroup,

    SUM(CASE WHEN TransactionType = 'Deposit'
             THEN COALESCE(Amount_GBP, 0) ELSE 0 END) AS Gross_Deposits_GBP,

    SUM(CASE WHEN TransactionType IN ('Withdrawal', 'Full Withdrawal')
             THEN ABS(COALESCE(Amount_GBP, 0)) ELSE 0 END) AS Gross_Withdrawals_GBP
  FROM txn_enriched
  GROUP BY
    Date, WeekStart, Month, Year,
    FTD_YearMonth, Reg_YearMonth, Gender, Channel, SubChannel, BirthCohort,
    ProductGroup
)

SELECT
  Date,
  WeekStart,
  Month,
  Year,

  FTD_YearMonth,
  Reg_YearMonth,
  Gender,
  Channel,
  SubChannel,
  BirthCohort,

  ProductGroup,

  Gross_Deposits_GBP,
  Gross_Withdrawals_GBP,
  (Gross_Deposits_GBP - Gross_Withdrawals_GBP) AS Net_Deposits_GBP
FROM daily
ORDER BY Date, ProductGroup