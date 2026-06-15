/* ============================================================================
DAILY FUNNEL COUNTS (Moneyfarm) — UK users only — OUTPUT EventDate >= 2025-01-01

EXEC SUMMARY (for anyone reading this later)
- Goal: daily funnel counts for Moneyfarm UK with a clean “event-first, Silver-second” approach.
- Why: the events stream has a 1-day latency (and only exists from 2025-01-01 onwards), while Silver AUM contains the
  long history needed to correctly identify legacy portfolios / first funding proof.
- How:
  1) Build a complete portfolio universe (events + Silver AUM).
  2) Resolve portfolio created date using events first, then Silver first appearance.
  3) Resolve “first funding proof” using:
       - events only when we can prove deposit is post portfolio_created for that same portfolio id,
       - otherwise fall back to Silver “Total_Investments goes 0 -> >0 (or >0 on first row)” proof.
  4) Build user-level “first ever” dates (first funded user, first portfolio created user) across *all* portfolios.
  5) Enrich with dim_customer + channel + FTD platform + affiliate attributes for filtering.
- Output: segmented daily counts by (Gender, Channel, SubChannel, Product, FTDPlatform, AffiliateID, AffiliatesGroupsName, Contact)
  with 3 simple ratios derived from existing columns.

Adds (ratio view):
- Reg_to_FTD_Ratio                    = GlobalFTD_Users / Registered_Users
- Reg_to_TnCs_Ratio                   = AcceptedTnCs_Users / Registered_Users
- Reg_to_FirstPortfolioCreated_Ratio  = First_Portfolio_Created_Users / Registered_Users

Day-delay alignment:
- base_events: CreatedAtTs < current_date()
- aum_raw/aum_base: etr_ymd < current_date()
============================================================================ */

WITH aum_raw AS (
  /* Silver AUM is our long-history backbone (no lower bound; only exclude current day due to ingestion timing). */
  SELECT
      GCID,
      Identifier_Value,
      Portfolio_Id,
      CAST(etr_ymd AS DATE) AS etr_ymd,
      Product,
      Portfolio_Model_Id,            -- ADDED
      Market_Value,
      Total_Investments,
      Total_Disinvestments,
      SourceFile,

      REGEXP_EXTRACT(SourceFile, '(\\d{8}T\\d{4})', 1) AS sf_ts_raw,
      CASE
        WHEN REGEXP_EXTRACT(SourceFile, '(\\d{8}T\\d{4})', 1) IS NOT NULL
          THEN TO_TIMESTAMP(REPLACE(REGEXP_EXTRACT(SourceFile, '(\\d{8}T\\d{4})', 1), 'T', ''), 'yyyyMMddHHmm')
        ELSE NULL
      END AS sf_ts
  FROM money_farm.silver_moneyfarm_etoro_mf_aum
  WHERE CAST(etr_ymd AS DATE) < CURRENT_DATE()
),

aum_dedup AS (
  /* Silver can have multiple files per day; pick the newest file (by embedded timestamp) per GCID/portfolio/day. */
  SELECT *
  FROM (
    SELECT
      r.*,
      ROW_NUMBER() OVER (
        PARTITION BY r.GCID, r.Identifier_Value, r.Portfolio_Id, r.etr_ymd
        ORDER BY
          CASE WHEN r.SourceFile IS NOT NULL THEN 1 ELSE 0 END DESC,
          r.sf_ts DESC NULLS LAST
      ) AS rn
    FROM aum_raw r
  ) x
  WHERE rn = 1
),

aum_base AS (
  SELECT
      GCID,
      Portfolio_Id                                    AS PortfolioID_SILVER,
      etr_ymd                                         AS etr_ymd,
      NULLIF(TRIM(Product), '')                       AS Product_SILVER_NORM,
      NULLIF(TRIM(CAST(Portfolio_Model_Id AS STRING)), '') AS Portfolio_Model_Id_SILVER_NORM,  -- ADDED
      TRY_CAST(Market_Value AS DECIMAL(18,2))         AS Market_Value_SILVER,
      TRY_CAST(Total_Investments AS DECIMAL(18,2))    AS Total_Investments_SILVER,
      TRY_CAST(Total_Disinvestments AS DECIMAL(18,2)) AS Total_Disinvestments_SILVER
  FROM aum_dedup
  WHERE Portfolio_Id IS NOT NULL
),

/* Silver-derived helpers (enrichment / fallback) */
aum_keys AS (
  SELECT DISTINCT GCID, PortfolioID_SILVER
  FROM aum_base
),

aum_first AS (
  /* First day a portfolio appears in Silver (fallback “created” signal if events are missing). */
  SELECT
      GCID,
      PortfolioID_SILVER,
      MIN(etr_ymd) AS FirstAppearance_SILVER
  FROM aum_base
  GROUP BY GCID, PortfolioID_SILVER
),

/* Product in Silver can be blank some days; resolve a stable value using first nonblank else latest nonblank. */
aum_product_first_nonblank AS (
  SELECT GCID, PortfolioID_SILVER, MIN(etr_ymd) AS first_nonblank_ymd
  FROM aum_base
  WHERE Product_SILVER_NORM IS NOT NULL
  GROUP BY GCID, PortfolioID_SILVER
),
aum_product_latest_nonblank AS (
  SELECT GCID, PortfolioID_SILVER, MAX(etr_ymd) AS latest_nonblank_ymd
  FROM aum_base
  WHERE Product_SILVER_NORM IS NOT NULL
  GROUP BY GCID, PortfolioID_SILVER
),
aum_product_first_pick AS (
  SELECT b.GCID, b.PortfolioID_SILVER, b.Product_SILVER_NORM AS Product_SILVER_FIRST_NONNULL
  FROM aum_base b
  JOIN aum_product_first_nonblank f
    ON  b.GCID = f.GCID
    AND b.PortfolioID_SILVER = f.PortfolioID_SILVER
    AND b.etr_ymd = f.first_nonblank_ymd
),
aum_product_latest_pick AS (
  SELECT b.GCID, b.PortfolioID_SILVER, b.Product_SILVER_NORM AS Product_SILVER_LATEST_NONNULL
  FROM aum_base b
  JOIN aum_product_latest_nonblank f
    ON  b.GCID = f.GCID
    AND b.PortfolioID_SILVER = f.PortfolioID_SILVER
    AND b.etr_ymd = f.latest_nonblank_ymd
),
aum_product_resolved AS (
  SELECT
      k.GCID,
      k.PortfolioID_SILVER,
      COALESCE(fp.Product_SILVER_FIRST_NONNULL, lp.Product_SILVER_LATEST_NONNULL) AS Product_SILVER_RESOLVED
  FROM aum_keys k
  LEFT JOIN aum_product_first_pick  fp ON fp.GCID = k.GCID AND fp.PortfolioID_SILVER = k.PortfolioID_SILVER
  LEFT JOIN aum_product_latest_pick lp ON lp.GCID = k.GCID AND lp.PortfolioID_SILVER = k.PortfolioID_SILVER
),

/* Resolve Portfolio_Model_Id from Silver: latest non-blank (per portfolio) */
aum_model_latest_nonblank AS (   -- ADDED
  SELECT GCID, PortfolioID_SILVER, MAX(etr_ymd) AS latest_model_ymd
  FROM aum_base
  WHERE Portfolio_Model_Id_SILVER_NORM IS NOT NULL
  GROUP BY GCID, PortfolioID_SILVER
),
aum_model_latest_pick AS (       -- ADDED
  SELECT b.GCID, b.PortfolioID_SILVER, b.Portfolio_Model_Id_SILVER_NORM AS Portfolio_Model_Id_SILVER_LATEST_NONNULL
  FROM aum_base b
  JOIN aum_model_latest_nonblank m
    ON  b.GCID = m.GCID
    AND b.PortfolioID_SILVER = m.PortfolioID_SILVER
    AND b.etr_ymd = m.latest_model_ymd
),

/* ===== Silver proof for legacy portfolios: first day TI goes 0->>0 (or >0 on first row) =====
   Why: if a portfolio existed before the events stream started, we can’t “prove” first deposit from events shown today.
   Silver TI is the only defensible backfill for “this portfolio has been funded at least once”. */
aum_ti_transitions AS (
  SELECT
    GCID,
    PortfolioID_SILVER,
    etr_ymd,
    Total_Investments_SILVER AS TI,
    LAG(Total_Investments_SILVER) OVER (
      PARTITION BY GCID, PortfolioID_SILVER
      ORDER BY etr_ymd
    ) AS prev_TI
  FROM aum_base
),

aum_first_fund_proof AS (
  SELECT
    GCID,
    PortfolioID_SILVER,
    MIN(etr_ymd) AS FirstFundDate_AUM_Proof
  FROM aum_ti_transitions
  WHERE TI > 0
    AND (prev_TI IS NULL OR prev_TI <= 0)
  GROUP BY GCID, PortfolioID_SILVER
),

/* Events stream (1-day delay) + 2025-01-01 cutoff
   Why cutoff here: the stream doesn’t exist pre-2025 in a reliable way, but Silver covers legacy anyway. */
base_events AS (
  SELECT
      EventPayloadRowData_EventMetadata_Gcid                    AS GCID,
      EventPayloadRowData_EventMetadata_EventType               AS EventType,
      TO_TIMESTAMP(EventPayloadRowData_EventMetadata_CreatedAt) AS CreatedAtTs,
      EventPayloadRowData_EventData                             AS EventDataStr
  FROM main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts
  WHERE EventPayloadRowData_ProviderName = 'Moneyfarm'
    AND TO_TIMESTAMP(EventPayloadRowData_EventMetadata_CreatedAt) < CURRENT_DATE()
    AND TO_TIMESTAMP(EventPayloadRowData_EventMetadata_CreatedAt) >= TIMESTAMP '2025-01-01 00:00:00'
),

with_data_outer AS (
  SELECT b.*, FROM_JSON(b.EventDataStr, 'STRUCT<data STRING>') AS outer_obj
  FROM base_events b
),

/* PORTFOLIO_CREATED (events) */
pc_raw AS (
  SELECT
    GCID,
    CreatedAtTs,
    FROM_JSON(outer_obj.data, 'STRUCT<portfolioId STRING, productId STRING>') AS inner_pc
  FROM with_data_outer
  WHERE EventType = 'PORTFOLIO_CREATED'
),
pc_norm AS (
  SELECT
    GCID,
    inner_pc.portfolioId AS PortfolioID_EVENT,
    inner_pc.productId   AS ProductID_EVENT,
    CreatedAtTs
  FROM pc_raw
  WHERE inner_pc.portfolioId IS NOT NULL
),
pc_first AS (
  SELECT
      GCID,
      PortfolioID_EVENT,
      FIRST_VALUE(ProductID_EVENT) OVER (PARTITION BY GCID, PortfolioID_EVENT ORDER BY CreatedAtTs ASC) AS ProductID_EVENT,
      MIN(CreatedAtTs)            OVER (PARTITION BY GCID, PortfolioID_EVENT)                           AS PortfolioCreatedTs_EVENT
  FROM pc_norm
),
pc_dedup AS (
  SELECT DISTINCT
    GCID,
    PortfolioID_EVENT,
    ProductID_EVENT,
    PortfolioCreatedTs_EVENT
  FROM pc_first
),

/* PORTFOLIO_DEPOSIT (events) */
pd_raw AS (
  SELECT
    GCID,
    CreatedAtTs,
    FROM_JSON(outer_obj.data, 'STRUCT<portfolioId STRING, amount STRING, currency STRING, valueDate STRING>') AS inner_pd
  FROM with_data_outer
  WHERE EventType = 'PORTFOLIO_DEPOSIT'
),
pd_norm AS (
  SELECT
      GCID,
      inner_pd.portfolioId                       AS PortfolioID_EVENT,
      CreatedAtTs                                AS DepositCreatedAtTs_EVENT,
      TRY_CAST(inner_pd.amount AS DECIMAL(18,2)) AS DepositAmount_EVENT
  FROM pd_raw
  WHERE inner_pd.portfolioId IS NOT NULL
),

/* ===== Event-proven first deposit: ONLY for portfolios that have a PORTFOLIO_CREATED event =====
   Why: without a created event we can’t prove “first” from the event stream (portfolio may be legacy). */
pd_first_after_create AS (
  SELECT
    pc.GCID,
    pc.PortfolioID_EVENT,
    MIN(pd.DepositCreatedAtTs_EVENT) AS FirstDepositAfterCreateTs_EVENT
  FROM pc_dedup pc
  JOIN pd_norm pd
    ON pd.GCID = pc.GCID
   AND pd.PortfolioID_EVENT = pc.PortfolioID_EVENT
   AND pd.DepositCreatedAtTs_EVENT >= pc.PortfolioCreatedTs_EVENT
  GROUP BY pc.GCID, pc.PortfolioID_EVENT
),

/* Bronze users (Moneyfarm, 1-day delay) + 2025-01-01 cutoff */
bronze_users AS (
  SELECT DISTINCT
    gcid              AS GCID,
    createdAtDateTime AS BronzeCreatedAt
  FROM main.bi_db.bronze_sub_accounts_accounts
  WHERE LOWER(providerName) = 'moneyfarm'
    AND createdAtDateTime < CURRENT_DATE()
    AND CAST(createdAtDateTime AS DATE) >= DATE '2025-01-01'
),

/* User-level events */
user_createaccount AS (
  SELECT GCID, MIN(CreatedAtTs) AS CreateAccountTs
  FROM base_events
  WHERE EventType = 'CreateAccount'
  GROUP BY GCID
),
user_ucaa AS (
  SELECT GCID, MIN(CreatedAtTs) AS Cash_Account_Activated_Ts
  FROM base_events
  WHERE EventType = 'USER_CASH_ACCOUNT_ACTIVATED'
  GROUP BY GCID
),

/* dim_customer REG/FTD event sets only (pruned by event date)
   Why: these are “independent” daily events and we only want output from 2025-01-01 onwards. */
reg_events AS (
  SELECT
    dc.GCID,
    CAST(dc.RegisteredReal AS DATE) AS EventDate
  FROM main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer dc
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country cu
    ON dc.CountryID = cu.CountryID
  WHERE cu.MarketingRegionManualName = 'UK'
    AND CAST(dc.RegisteredReal AS DATE) >= DATE '2025-01-01'
    AND dc.IsValidCustomer = 1
),

global_ftd_events AS (
  SELECT
    dc.GCID,
    CAST(dc.FirstDepositDate AS DATE) AS EventDate
  FROM main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer dc
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country cu
    ON dc.CountryID = cu.CountryID
  WHERE cu.MarketingRegionManualName = 'UK'
    AND DATE_FORMAT(dc.FirstDepositDate, 'yyyy-MM') <> '1900-01'
    AND CAST(dc.FirstDepositDate AS DATE) >= DATE '2025-01-01'
    AND dc.IsValidCustomer = 1
),

/* AcceptedTnCs / UCAA dates */
user_dates AS (
  SELECT
    u.GCID,
    CAST(COALESCE(ca.CreateAccountTs, bu.BronzeCreatedAt) AS DATE) AS AcceptedTnCs_Date,
    CAST(ucaa.Cash_Account_Activated_Ts AS DATE)                   AS UCAA_Date
  FROM (
    SELECT DISTINCT GCID
    FROM (
      SELECT GCID FROM reg_events
      UNION
      SELECT GCID FROM global_ftd_events
      UNION
      SELECT GCID FROM bronze_users
      UNION
      SELECT GCID FROM base_events
      UNION
      SELECT GCID FROM aum_base
    ) g
  ) u
  LEFT JOIN user_createaccount ca ON ca.GCID = u.GCID
  LEFT JOIN bronze_users bu       ON bu.GCID = u.GCID
  LEFT JOIN user_ucaa ucaa        ON ucaa.GCID = u.GCID
),

/* ============================================================================
EVENT-FIRST portfolio universe + lifecycle, with correct proof logic
============================================================================ */
portfolio_keys AS (
  SELECT DISTINCT GCID, PortfolioID_EVENT AS PortfolioID
  FROM pc_dedup
  UNION
  SELECT DISTINCT GCID, PortfolioID_EVENT AS PortfolioID
  FROM pd_norm
  UNION
  SELECT DISTINCT GCID, PortfolioID_SILVER AS PortfolioID
  FROM aum_base
),

portfolio_lifecycle AS (
  SELECT
    k.GCID,
    k.PortfolioID,

    /* Created date: prefer events, fallback to Silver first appearance. */
    CAST(COALESCE(pc.PortfolioCreatedTs_EVENT, af.FirstAppearance_SILVER) AS DATE) AS PortfolioCreatedDate,

    /* Product: prefer events, fallback to resolved Silver product. */
    COALESCE(pc.ProductID_EVENT, apr.Product_SILVER_RESOLVED) AS ProductCode,

    /* Model ID: resolved from Silver (latest known non-null) for product name enrichment. */
    mlp.Portfolio_Model_Id_SILVER_LATEST_NONNULL AS Portfolio_Model_Id_Resolved,  -- ADDED

    /* First fund proof: only “event-first” when we can prove deposit comes after create; else use Silver TI proof. */
    CAST(
      CASE
        WHEN pc.PortfolioID_EVENT IS NOT NULL
          THEN pdc.FirstDepositAfterCreateTs_EVENT
        ELSE afp.FirstFundDate_AUM_Proof
      END AS DATE
    ) AS PortfolioFirstFundDate

  FROM portfolio_keys k
  LEFT JOIN pc_dedup pc
    ON pc.GCID = k.GCID
   AND pc.PortfolioID_EVENT = k.PortfolioID
  LEFT JOIN pd_first_after_create pdc
    ON pdc.GCID = k.GCID
   AND pdc.PortfolioID_EVENT = k.PortfolioID
  LEFT JOIN aum_first af
    ON af.GCID = k.GCID
   AND af.PortfolioID_SILVER = k.PortfolioID
  LEFT JOIN aum_product_resolved apr
    ON apr.GCID = k.GCID
   AND apr.PortfolioID_SILVER = k.PortfolioID
  LEFT JOIN aum_model_latest_pick mlp                      -- ADDED
    ON mlp.GCID = k.GCID
   AND mlp.PortfolioID_SILVER = k.PortfolioID
  LEFT JOIN aum_first_fund_proof afp
    ON afp.GCID = k.GCID
   AND afp.PortfolioID_SILVER = k.PortfolioID
),

portfolio_labeled AS (
  SELECT
    p.GCID,
    p.PortfolioID,
    p.PortfolioCreatedDate,
    p.PortfolioFirstFundDate,
    COALESCE(p.ProductCode, 'None') AS ProductName_Code,
    CASE
      WHEN LOWER(COALESCE(p.ProductCode, '')) = 'isa-cash'
       AND LOWER(COALESCE(p.Portfolio_Model_Id_Resolved, '')) = 'etoro-gb-r0-c1-cash-saving-account-v2'
        THEN 'Cash ISA - V2'
      ELSE
        CASE LOWER(COALESCE(p.ProductCode, ''))
          WHEN 'isa-discretionary'      THEN 'Managed ISA'
          WHEN 'gia-discretionary'      THEN 'Managed General Investment Account'
          WHEN 'jisa-discretionary'     THEN 'Managed Junior ISA'
          WHEN 'sipp-discretionary'     THEN 'Managed Self-Invested Personal Pension'
          WHEN 'gia-execution-only'     THEN 'DIY General Investment Account'
          WHEN 'isa-execution-only'     THEN 'DIY ISA'
          WHEN 'jisa-execution-only'    THEN 'DIY Junior ISA'
          WHEN 'isa-cash'               THEN 'Cash ISA'
          WHEN ''                       THEN 'None'
          ELSE p.ProductCode
        END
    END AS ProductName
  FROM portfolio_lifecycle p
),

/* ===== USER-level first funded date (across ALL portfolios, incl. legacy) ===== */
user_first_fund_date AS (
  SELECT
    GCID,
    MIN(PortfolioFirstFundDate) AS UserFirstFundDate
  FROM portfolio_labeled
  WHERE PortfolioFirstFundDate IS NOT NULL
  GROUP BY GCID
),

/* Representative portfolio on user's first funded date (for product attribution) */
user_first_fund_portfolio AS (
  SELECT *
  FROM (
    SELECT
      pl.GCID,
      pl.PortfolioID,
      pl.PortfolioFirstFundDate,
      pl.ProductName_Code,
      pl.ProductName,
      ROW_NUMBER() OVER (
        PARTITION BY pl.GCID
        ORDER BY pl.PortfolioFirstFundDate ASC, pl.PortfolioID ASC
      ) AS rn
    FROM portfolio_labeled pl
    JOIN user_first_fund_date uf
      ON uf.GCID = pl.GCID
     AND uf.UserFirstFundDate = pl.PortfolioFirstFundDate
  ) x
  WHERE rn = 1
),

/* ===== USER-level first portfolio created date (across ALL portfolios) ===== */
user_first_portfolio_created_date AS (
  SELECT
    GCID,
    MIN(PortfolioCreatedDate) AS UserFirstPortfolioCreatedDate
  FROM portfolio_labeled
  WHERE PortfolioCreatedDate IS NOT NULL
  GROUP BY GCID
),

/* Representative portfolio on user's first portfolio created date (for product attribution) */
user_first_portfolio_created_pick AS (
  SELECT *
  FROM (
    SELECT
      pl.GCID,
      pl.PortfolioID,
      pl.PortfolioCreatedDate,
      pl.ProductName_Code,
      pl.ProductName,
      ROW_NUMBER() OVER (
        PARTITION BY pl.GCID
        ORDER BY pl.PortfolioCreatedDate ASC, pl.PortfolioID ASC
      ) AS rn
    FROM portfolio_labeled pl
    JOIN user_first_portfolio_created_date up
      ON up.GCID = pl.GCID
     AND up.UserFirstPortfolioCreatedDate = pl.PortfolioCreatedDate
  ) x
  WHERE rn = 1
),

ftd_platform_dict AS (
  SELECT ID, Name
  FROM main.bi_db.bronze_moneybusdb_dictionary_accounttypes
),

/* GCID universe for enrichment — keeps dim_customer scan small. */
gcid_universe AS (
  SELECT DISTINCT GCID
  FROM (
    SELECT GCID FROM reg_events
    UNION
    SELECT GCID FROM global_ftd_events
    UNION
    SELECT GCID FROM user_dates
    UNION
    SELECT GCID FROM portfolio_labeled
  ) u
),

/* Targeted dim_customer lookup only for relevant GCIDs + affiliate enrichment.
   Why: affiliate details are “static-ish” attributes used for slicing funnel performance. */
dim_customer_lookup AS (
  SELECT
    dc.GCID,
    dc.Gender,
    ch.Channel,
    ch.SubChannel,

    CASE
      WHEN DATE_FORMAT(dc.FirstDepositDate, 'yyyy-MM') = '1900-01' THEN NULL
      ELSE dc.FTDPlatformID
    END AS FTDPlatformID,
    ftd.Name AS FTDPlatformName,

    dc.AffiliateID,
    da.AffiliatesGroupsName,
    da.Contact
  FROM gcid_universe u
  JOIN main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer dc
    ON dc.GCID = u.GCID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country cu
    ON dc.CountryID = cu.CountryID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel ch
    ON dc.SubChannelID = ch.SubChannelID
  LEFT JOIN ftd_platform_dict ftd
    ON ftd.ID = CASE
                  WHEN DATE_FORMAT(dc.FirstDepositDate, 'yyyy-MM') = '1900-01' THEN NULL
                  ELSE dc.FTDPlatformID
                END
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked da
    ON dc.AffiliateID = da.AffiliateID
  WHERE cu.MarketingRegionManualName = 'UK'
),

/* Build an “event rows” table at the final reporting grain. Each union corresponds to one funnel milestone. */
event_rows AS (

  SELECT DISTINCT
    r.EventDate,
    r.GCID,
    CAST(NULL AS STRING) AS PortfolioID,
    d.Gender,
    d.Channel,
    d.SubChannel,
    'None' AS ProductName_Code,
    'None' AS ProductName,
    d.FTDPlatformID,
    d.FTDPlatformName,
    d.AffiliateID,
    d.AffiliatesGroupsName,
    d.Contact,
    'REGISTERED' AS EventType
  FROM reg_events r
  LEFT JOIN dim_customer_lookup d
    ON d.GCID = r.GCID

  UNION ALL

  SELECT DISTINCT
    g.EventDate,
    g.GCID,
    CAST(NULL AS STRING) AS PortfolioID,
    d.Gender,
    d.Channel,
    d.SubChannel,
    'None' AS ProductName_Code,
    'None' AS ProductName,
    d.FTDPlatformID,
    d.FTDPlatformName,
    d.AffiliateID,
    d.AffiliatesGroupsName,
    d.Contact,
    'GLOBAL_FTD' AS EventType
  FROM global_ftd_events g
  LEFT JOIN dim_customer_lookup d
    ON d.GCID = g.GCID

  UNION ALL

  SELECT DISTINCT
    ud.AcceptedTnCs_Date AS EventDate,
    ud.GCID,
    CAST(NULL AS STRING) AS PortfolioID,
    d.Gender,
    d.Channel,
    d.SubChannel,
    'None' AS ProductName_Code,
    'None' AS ProductName,
    d.FTDPlatformID,
    d.FTDPlatformName,
    d.AffiliateID,
    d.AffiliatesGroupsName,
    d.Contact,
    'ACCEPTED_TNCS' AS EventType
  FROM user_dates ud
  LEFT JOIN dim_customer_lookup d
    ON d.GCID = ud.GCID
  WHERE ud.AcceptedTnCs_Date IS NOT NULL

  UNION ALL

  SELECT DISTINCT
    ud.UCAA_Date AS EventDate,
    ud.GCID,
    CAST(NULL AS STRING) AS PortfolioID,
    d.Gender,
    d.Channel,
    d.SubChannel,
    'None' AS ProductName_Code,
    'None' AS ProductName,
    d.FTDPlatformID,
    d.FTDPlatformName,
    d.AffiliateID,
    d.AffiliatesGroupsName,
    d.Contact,
    'UCAA' AS EventType
  FROM user_dates ud
  LEFT JOIN dim_customer_lookup d
    ON d.GCID = ud.GCID
  WHERE ud.UCAA_Date IS NOT NULL

  UNION ALL

  SELECT DISTINCT
    pl.PortfolioCreatedDate AS EventDate,
    pl.GCID,
    pl.PortfolioID AS PortfolioID,
    d.Gender,
    d.Channel,
    d.SubChannel,
    COALESCE(pl.ProductName_Code, 'None') AS ProductName_Code,
    COALESCE(pl.ProductName, 'None')      AS ProductName,
    d.FTDPlatformID,
    d.FTDPlatformName,
    d.AffiliateID,
    d.AffiliatesGroupsName,
    d.Contact,
    'PORTFOLIO_CREATED' AS EventType
  FROM portfolio_labeled pl
  LEFT JOIN dim_customer_lookup d
    ON d.GCID = pl.GCID
  WHERE pl.PortfolioCreatedDate IS NOT NULL

  UNION ALL

  /* Portfolio-level first fund: measures “newly funded portfolios” independent of user history. */
  SELECT DISTINCT
    pl.PortfolioFirstFundDate AS EventDate,
    pl.GCID,
    pl.PortfolioID AS PortfolioID,
    d.Gender,
    d.Channel,
    d.SubChannel,
    COALESCE(pl.ProductName_Code, 'None') AS ProductName_Code,
    COALESCE(pl.ProductName, 'None')      AS ProductName,
    d.FTDPlatformID,
    d.FTDPlatformName,
    d.AffiliateID,
    d.AffiliatesGroupsName,
    d.Contact,
    'PORTFOLIO_FIRST_FUND' AS EventType
  FROM portfolio_labeled pl
  LEFT JOIN dim_customer_lookup d
    ON d.GCID = pl.GCID
  WHERE pl.PortfolioFirstFundDate IS NOT NULL

  UNION ALL

  /* User-level first ever fund: avoids counting first deposit into a user’s 2nd/3rd portfolio as “first funded user”. */
  SELECT DISTINCT
    uf.PortfolioFirstFundDate AS EventDate,
    uf.GCID,
    CAST(NULL AS STRING) AS PortfolioID,
    d.Gender,
    d.Channel,
    d.SubChannel,
    COALESCE(uf.ProductName_Code, 'None') AS ProductName_Code,
    COALESCE(uf.ProductName, 'None')      AS ProductName,
    d.FTDPlatformID,
    d.FTDPlatformName,
    d.AffiliateID,
    d.AffiliatesGroupsName,
    d.Contact,
    'USER_FIRST_FUND' AS EventType
  FROM user_first_fund_portfolio uf
  LEFT JOIN dim_customer_lookup d
    ON d.GCID = uf.GCID
  WHERE uf.PortfolioFirstFundDate IS NOT NULL

  UNION ALL

  /* User-level first ever portfolio created: event-first via portfolio lifecycle, Silver fallback for legacy. */
  SELECT DISTINCT
    ufpc.PortfolioCreatedDate AS EventDate,
    ufpc.GCID,
    CAST(NULL AS STRING) AS PortfolioID,
    d.Gender,
    d.Channel,
    d.SubChannel,
    COALESCE(ufpc.ProductName_Code, 'None') AS ProductName_Code,
    COALESCE(ufpc.ProductName, 'None')      AS ProductName,
    d.FTDPlatformID,
    d.FTDPlatformName,
    d.AffiliateID,
    d.AffiliatesGroupsName,
    d.Contact,
    'USER_FIRST_PORTFOLIO_CREATED' AS EventType
  FROM user_first_portfolio_created_pick ufpc
  LEFT JOIN dim_customer_lookup d
    ON d.GCID = ufpc.GCID
  WHERE ufpc.PortfolioCreatedDate IS NOT NULL
),

event_rows_filtered AS (
  /* Final output window is from 2025-01-01 onward (even though Silver backfills reach earlier). */
  SELECT *
  FROM event_rows
  WHERE EventDate >= DATE '2025-01-01'
),

/* Aggregate funnel counts at the reporting grain. */
funnel_daily AS (
  SELECT
    e.EventDate,

    e.Gender,
    e.Channel,
    e.SubChannel,

    e.ProductName_Code,
    e.ProductName,

    e.FTDPlatformID,
    e.FTDPlatformName,

    e.AffiliateID,
    e.AffiliatesGroupsName,
    e.Contact,

    COUNT(DISTINCT CASE WHEN e.EventType = 'REGISTERED'                   THEN e.GCID END) AS Registered_Users,
    COUNT(DISTINCT CASE WHEN e.EventType = 'GLOBAL_FTD'                   THEN e.GCID END) AS GlobalFTD_Users,
    COUNT(DISTINCT CASE WHEN e.EventType = 'ACCEPTED_TNCS'                THEN e.GCID END) AS AcceptedTnCs_Users,
    COUNT(DISTINCT CASE WHEN e.EventType = 'UCAA'                         THEN e.GCID END) AS UCAA_Users,
    COUNT(DISTINCT CASE WHEN e.EventType = 'PORTFOLIO_CREATED'            THEN e.GCID END) AS PortfolioCreated_Users,
    COUNT(DISTINCT CASE WHEN e.EventType = 'USER_FIRST_PORTFOLIO_CREATED' THEN e.GCID END) AS First_Portfolio_Created_Users,
    COUNT(DISTINCT CASE WHEN e.EventType = 'USER_FIRST_FUND'              THEN e.GCID END) AS ISA_First_Deposit_Users,
    COUNT(DISTINCT CASE WHEN e.EventType = 'PORTFOLIO_FIRST_FUND'         THEN e.PortfolioID END) AS First_Funded_Portfolios

  FROM event_rows_filtered e
  GROUP BY
    e.EventDate,
    e.Gender,
    e.Channel,
    e.SubChannel,
    e.ProductName_Code,
    e.ProductName,
    e.FTDPlatformID,
    e.FTDPlatformName,
    e.AffiliateID,
    e.AffiliatesGroupsName,
    e.Contact
)

SELECT
  f.EventDate,

  f.Gender,
  f.Channel,
  f.SubChannel,

  f.ProductName_Code,
  f.ProductName,

  f.FTDPlatformID,
  f.FTDPlatformName,

  f.AffiliateID,
  f.AffiliatesGroupsName,
  f.Contact,

  f.Registered_Users,
  f.GlobalFTD_Users,
  f.AcceptedTnCs_Users,
  f.UCAA_Users,
  f.PortfolioCreated_Users,
  f.First_Portfolio_Created_Users,
  f.ISA_First_Deposit_Users,
  f.First_Funded_Portfolios

  -- /* Ratios (division at the same grain as the row). */
  -- CASE WHEN f.Registered_Users = 0 THEN NULL
  --      ELSE (f.GlobalFTD_Users * 1.0) / f.Registered_Users END AS Reg_to_FTD_Ratio,

  -- CASE WHEN f.Registered_Users = 0 THEN NULL
  --      ELSE (f.AcceptedTnCs_Users * 1.0) / f.Registered_Users END AS Reg_to_TnCs_Ratio,

  -- CASE WHEN f.Registered_Users = 0 THEN NULL
  --      ELSE (f.First_Portfolio_Created_Users * 1.0) / f.Registered_Users END AS Reg_to_FirstPortfolioCreated_Ratio

FROM funnel_daily f