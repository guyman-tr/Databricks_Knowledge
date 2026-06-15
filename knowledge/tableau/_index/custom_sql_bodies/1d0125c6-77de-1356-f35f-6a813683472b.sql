-- Identify each user's earliest Moneyfarm (ISA) deposit, attach product and amount
WITH base AS (
  SELECT
      EventPayloadRowData_EventMetadata_Gcid                    AS GCID,
      EventPayloadRowData_EventMetadata_EventType               AS EventType,
      to_timestamp(EventPayloadRowData_EventMetadata_CreatedAt) AS CreatedAtTs,
      EventPayloadRowData_EventData                             AS EventDataStr
  FROM main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts
  WHERE EventPayloadRowData_ProviderName = 'Moneyfarm'
),

with_data_outer AS (
  SELECT
      b.*,
      from_json(b.EventDataStr, 'STRUCT<data STRING>') AS outer_obj
  FROM base b
),

-- Portfolio CREATED (dedup to earliest per GCID × PortfolioID)
pc_norm AS (
  SELECT
      GCID,
      CreatedAtTs,
      from_json(outer_obj.data, 'STRUCT<portfolioId STRING, productId STRING>') AS inner_pc
  FROM with_data_outer
  WHERE EventType = 'PORTFOLIO_CREATED'
),
pc_dedup AS (
  SELECT DISTINCT
      GCID,
      inner_pc.portfolioId AS PortfolioID,
      first_value(inner_pc.productId)
        OVER (PARTITION BY GCID, inner_pc.portfolioId ORDER BY CreatedAtTs ASC) AS ProductID
  FROM pc_norm
  WHERE inner_pc.portfolioId IS NOT NULL
),

-- Portfolio DEPOSIT
pd_norm AS (
  SELECT
      GCID,
      CreatedAtTs AS DepositEventTs,
      from_json(
        outer_obj.data,
        'STRUCT<portfolioId STRING, amount STRING, currency STRING, valueDate STRING>'
      ) AS inner_pd
  FROM with_data_outer
  WHERE EventType = 'PORTFOLIO_DEPOSIT'
),

-- Earliest deposit per GCID (keep portfolioId and amount)
pd_first_user AS (
  SELECT *
  FROM (
    SELECT
        GCID,
        inner_pd.portfolioId AS PortfolioID,
        try_cast(inner_pd.amount AS DECIMAL(18,4)) AS GBP_FTDA,
        DepositEventTs,
        row_number() OVER (PARTITION BY GCID ORDER BY DepositEventTs ASC) AS rn
    FROM pd_norm
    WHERE inner_pd.portfolioId IS NOT NULL
  ) x
  WHERE rn = 1
),

/* ================= SILVER AUM PRODUCT BACKFILL (DEDUP SAFE) ================= */

aum_raw AS (
  SELECT
      GCID,
      Portfolio_Id                                AS PortfolioID_SILVER,
      cast(etr_ymd AS date)                       AS etr_ymd,
      nullif(trim(Product), '')                   AS Product_SILVER_NORM
  FROM money_farm.silver_moneyfarm_etoro_mf_aum
  WHERE Product IS NOT NULL AND trim(Product) <> ''
),

-- Earliest non-null product per GCID × PortfolioID_SILVER
aum_product_ranked AS (
  SELECT
      GCID,
      PortfolioID_SILVER,
      Product_SILVER_NORM,
      row_number() OVER (
        PARTITION BY GCID, PortfolioID_SILVER
        ORDER BY etr_ymd ASC
      ) AS rn
  FROM aum_raw
),

aum_product_resolved AS (
  SELECT
      GCID,
      PortfolioID_SILVER,
      Product_SILVER_NORM AS Product_SILVER_RESOLVED
  FROM aum_product_ranked
  WHERE rn = 1   -- exactly one row per GCID × PortfolioID_SILVER
),

-- Attach productId for the portfolio where the first deposit happened,
-- using event product when available, else Silver product backfill
user_first_deposit_with_product AS (
  SELECT
      pdu.GCID,
      pdu.PortfolioID,
      pdu.DepositEventTs AS Event_FTD_Ts,
      pdu.GBP_FTDA,
      coalesce(pdp.ProductID, apr.Product_SILVER_RESOLVED) AS ProductID
  FROM pd_first_user pdu
  LEFT JOIN pc_dedup pdp
    ON pdp.GCID        = pdu.GCID
   AND pdp.PortfolioID = pdu.PortfolioID
  LEFT JOIN aum_product_resolved apr
    ON apr.GCID               = pdu.GCID
   AND apr.PortfolioID_SILVER = pdu.PortfolioID
),

-- Final per-user detail (now also exposing RealCID as CID)
Final AS (
  SELECT
    dc.GCID,
    CAST(dc.RealCID AS STRING) AS CID,
    date_format(dc.FirstDepositDate, 'yyyy-MM-dd') AS FTD_Date,
    CASE WHEN dc.FTDPlatformID = 4 THEN 'MoneyFarm' ELSE 'Other' END AS FTD_Platform,
    dc.AffiliateID,
    dch.Channel,
    dch.SubChannel,

    CASE
      WHEN date_format(dc.RegisteredReal, 'yyyy-MM-dd') >= DATE '2025-11-01' THEN 'Yes'
      ELSE 'No'
    END AS Reg_after_Oct_2025,

    CASE
      WHEN u.ProductID = 'isa-discretionary'    THEN 'Managed ISA'
      WHEN u.ProductID = 'gia-discretionary'    THEN 'Managed GIA'
      WHEN u.ProductID = 'jisa-discretionary'   THEN 'Managed Junior ISA'
      WHEN u.ProductID = 'sipp-discretionary'   THEN 'Managed SIPP'
      WHEN u.ProductID = 'gia-execution-only'   THEN 'DIY GIA'
      WHEN u.ProductID = 'isa-execution-only'   THEN 'DIY ISA'
      WHEN u.ProductID = 'jisa-execution-only'  THEN 'DIY JISA'
      WHEN u.ProductID = 'isa-cash'             THEN 'Cash ISA - QMMF'
      WHEN u.ProductID = 'available-cash'       THEN 'Uninvested cash'
      ELSE u.ProductID
    END AS Product_Label,

    date_format(u.Event_FTD_Ts, 'yyyy-MM-dd') AS Event_FTD_Date,
    u.GBP_FTDA,
    dc.FirstDepositAmount AS USD_FTDA,
    da.AffiliatesGroupsName,
    da.Contact
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked da
    ON dc.AffiliateID = da.AffiliateID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel dch
    ON dc.SubChannelID = dch.SubChannelID
  LEFT JOIN user_first_deposit_with_product u
    ON u.GCID = dc.GCID
  WHERE dc.FTDPlatformID = 4
)

-- USER-LEVEL OUTPUT (no aggregation)
SELECT
  f.GCID,
  f.CID,
  f.FTD_date,
  f.FTD_Platform,
  f.AffiliateID,
  f.Channel,
  f.SubChannel,
  f.AffiliatesGroupsName,
  f.Contact,
  f.Reg_after_Oct_2025,
  f.Product_label,
  f.Event_FTD_Date,
  f.GBP_FTDA,
  f.USD_FTDA
FROM Final f
ORDER BY f.FTD_date, f.GCID