WITH silver_ids AS (
  SELECT
    CAST(GCID AS STRING) AS GCID,
    MAX(NULLIF(TRIM(CAST(Identifier_Value AS STRING)), '')) AS ExternalID_Silver
  FROM main.money_farm.silver_moneyfarm_etoro_mf_aum
  GROUP BY CAST(GCID AS STRING)
),

-- UPDATED: use bronze_sub_accounts_accounts filtered to Moneyfarm
bronze_ids AS (
  SELECT
    CAST(gcid AS STRING) AS GCID,
    MAX(NULLIF(TRIM(CAST(externalUserId AS STRING)), '')) AS ExternalID_Bronze
  FROM main.bi_db.bronze_sub_accounts_accounts
  WHERE LOWER(providerName) = 'moneyfarm'
  GROUP BY CAST(gcid AS STRING)
),

all_gcids AS (
  SELECT GCID FROM silver_ids
  UNION
  SELECT GCID FROM bronze_ids
),

preferred_ids AS (
  SELECT
    a.GCID,
    COALESCE(s.ExternalID_Silver, b.ExternalID_Bronze) AS ExternalID,
    CASE
      WHEN s.GCID IS NOT NULL THEN 'Has open portfolio(s)'
      ELSE 'Onboarding, no open portfolio(s)'
    END AS `Onboarding Status`
  FROM all_gcids a
  LEFT JOIN silver_ids s ON s.GCID = a.GCID
  LEFT JOIN bronze_ids b ON b.GCID = a.GCID
),

aum_today AS (
  SELECT
    CAST(mf.GCID AS STRING)              AS GCID,
    CAST(mf.Portfolio_Id AS STRING)      AS Portfolio_Id,
    CAST(mf.Portfolio_Model_Id AS STRING) AS Portfolio_Model_Id,   -- NEW
    CAST(mf.Market_Value AS DOUBLE)      AS mv,
    mf.Product
  FROM main.money_farm.silver_moneyfarm_etoro_mf_aum mf
  WHERE TO_DATE(CAST(mf.etr_ymd AS STRING)) = CURRENT_DATE()
),

aum_labeled AS (
  SELECT
    t.GCID,
    t.Portfolio_Id,
    CASE
      -- isa-cash V2 by Portfolio_Model_Id (introduced 25/02/2026)
      WHEN MAX(t.Product) OVER (PARTITION BY t.GCID, t.Portfolio_Id) = 'isa-cash'
       AND MAX(t.Portfolio_Model_Id) OVER (PARTITION BY t.GCID, t.Portfolio_Id) = 'etoro-gb-r0-c1-cash-saving-account-v2'
        THEN 'Cash ISA - V2'

      -- existing mappings
      WHEN MAX(t.Product) OVER (PARTITION BY t.GCID, t.Portfolio_Id) = 'isa-discretionary'   THEN 'ISA, managed by MF'
      WHEN MAX(t.Product) OVER (PARTITION BY t.GCID, t.Portfolio_Id) = 'gia-discretionary'   THEN 'General Investment Account, managed by MF'
      WHEN MAX(t.Product) OVER (PARTITION BY t.GCID, t.Portfolio_Id) = 'jisa-discretionary'  THEN 'Junior ISA, managed by MF'
      WHEN MAX(t.Product) OVER (PARTITION BY t.GCID, t.Portfolio_Id) = 'sipp-discretionary'  THEN 'Self-Invested Personal Pension, managed by MF'
      WHEN MAX(t.Product) OVER (PARTITION BY t.GCID, t.Portfolio_Id) = 'gia-execution-only'  THEN 'General Investment Account, managed by customer (DIY)'
      WHEN MAX(t.Product) OVER (PARTITION BY t.GCID, t.Portfolio_Id) = 'isa-execution-only'  THEN 'ISA, managed by customer (DIY)'
      WHEN MAX(t.Product) OVER (PARTITION BY t.GCID, t.Portfolio_Id) = 'jisa-execution-only' THEN 'Junior ISA, managed by customer (DIY)'
      WHEN MAX(t.Product) OVER (PARTITION BY t.GCID, t.Portfolio_Id) = 'isa-cash'            THEN 'Cash ISA' -- any other/existing Cash ISA product
      WHEN MAX(t.Product) OVER (PARTITION BY t.GCID, t.Portfolio_Id) = 'available-cash'      THEN 'Uninvested cash'
      ELSE MAX(t.Product) OVER (PARTITION BY t.GCID, t.Portfolio_Id)
    END AS Product_Name,
    t.mv
  FROM aum_today t
),

today_per_portfolio AS (
  SELECT
    GCID,
    Portfolio_Id,
    Product_Name,
    CAST(ROUND(MAX(mv), 2) AS DECIMAL(38,2)) AS Product_Market_Value
  FROM aum_labeled
  GROUP BY GCID, Portfolio_Id, Product_Name
),

final AS (
  SELECT
    CAST(dc.RealCID AS STRING) AS CID,
    pid.GCID,
    pid.ExternalID,
    pid.`Onboarding Status`,
    COALESCE(tpp.Portfolio_Id, 'None') AS Portfolio_Id,
    COALESCE(tpp.Product_Name, 'None') AS Product_Name,
    COALESCE(tpp.Product_Market_Value, CAST(0.00 AS DECIMAL(38,2))) AS Product_Market_Value,
    CONCAT(dm.FirstName, ' ', dm.LastName) AS Current_Account_Manager
  FROM preferred_ids pid
  LEFT JOIN today_per_portfolio tpp
    ON tpp.GCID = pid.GCID
  LEFT JOIN main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer dc
    ON dc.GCID = pid.GCID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm
    ON dc.AccountManagerID = dm.ManagerID
)

SELECT * FROM final