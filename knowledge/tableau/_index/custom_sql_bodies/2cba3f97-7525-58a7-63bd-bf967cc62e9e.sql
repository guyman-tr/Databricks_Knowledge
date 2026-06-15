/* ============================================================================
MONEYFARM UK — Reg to same-day conversions — OUTPUT EventDate >= 2025-01-01

EXEC SUMMARY (so future-me doesn’t have to reverse engineer this)
- Goal: for each registration day, measure how many of those registrants also hit key milestones on the SAME calendar day.
- Why: this is the cleanest “speed of activation” view without mixing in later-day lag effects.
- Key design choices:
  1) Denominator is ALWAYS “Registered_Users” on that day, at the reporting grain.
  2) For SameDay_Reg_to_FTD and SameDay_Reg_to_TnCs we keep Product = 'None' because those milestones are user-level
     and don’t reliably map to a specific portfolio/product.
  3) For SameDay_Reg_to_FirstPortfolioCreated, we *do* attribute product using the user’s first-ever portfolio created pick
     (event-first, Silver fallback) so I can slice by product where it’s defensible.
  4) We enrich with dim_customer + channel + FTD platform + affiliate fields for filtering/slicing. If data isn’t present,
     it stays NULL (and groups into an “unknown” bucket).
  5) Databricks-specific: joins use null-safe equality (<=>) so NULLs match NULLs (no sentinel strings).

Outputs at grain:
EventDate + Gender/Channel/SubChannel + ProductName_Code/ProductName
        + FTDPlatformID/FTDPlatformName + AffiliateID/AffiliatesGroupsName/Contact

Includes:
- Registered_Users
- SameDay_Reg_to_FTD_Users + rate
- SameDay_Reg_to_AcceptedTnCs_Users + rate
- SameDay_Reg_to_FirstPortfolioCreated_Users + rate
============================================================================ */

WITH aum_raw AS (
  /* Silver AUM is used only to backfill “first portfolio created” where events are missing (legacy portfolios). */
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
  /* If multiple silver files land for the same day, take the latest. */
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
      Portfolio_Id AS PortfolioID_SILVER,
      etr_ymd      AS etr_ymd,
      NULLIF(TRIM(CAST(Portfolio_Model_Id AS STRING)), '') AS Portfolio_Model_Id_SILVER_NORM  -- ADDED
  FROM aum_dedup
  WHERE Portfolio_Id IS NOT NULL
),

aum_first AS (
  /* First Silver appearance of a portfolio = fallback “created” signal if no PORTFOLIO_CREATED event exists. */
  SELECT
      GCID,
      PortfolioID_SILVER,
      MIN(etr_ymd) AS FirstAppearance_SILVER
  FROM aum_base
  GROUP BY GCID, PortfolioID_SILVER
),

/* Resolve Portfolio_Model_Id from Silver: latest non-blank (per portfolio) */
aum_model_latest_nonblank AS (                -- ADDED
  SELECT GCID, PortfolioID_SILVER, MAX(etr_ymd) AS latest_model_ymd
  FROM aum_base
  WHERE Portfolio_Model_Id_SILVER_NORM IS NOT NULL
  GROUP BY GCID, PortfolioID_SILVER
),
aum_model_latest_pick AS (                    -- ADDED
  SELECT b.GCID, b.PortfolioID_SILVER, b.Portfolio_Model_Id_SILVER_NORM AS Portfolio_Model_Id_SILVER_LATEST_NONNULL
  FROM aum_base b
  JOIN aum_model_latest_nonblank m
    ON  b.GCID = m.GCID
    AND b.PortfolioID_SILVER = m.PortfolioID_SILVER
    AND b.etr_ymd = m.latest_model_ymd
),

/* Event stream (2025+) only used for PORTFOLIO_CREATED (preferred over Silver). */
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
pc_dedup AS (
  /* One row per GCID+portfolio with earliest created timestamp and the first productId seen. */
  SELECT DISTINCT
    GCID,
    PortfolioID_EVENT,
    FIRST_VALUE(ProductID_EVENT) OVER (PARTITION BY GCID, PortfolioID_EVENT ORDER BY CreatedAtTs ASC) AS ProductID_EVENT,
    MIN(CreatedAtTs)            OVER (PARTITION BY GCID, PortfolioID_EVENT)                           AS PortfolioCreatedTs_EVENT
  FROM pc_norm
),

/* ===== Portfolio universe and created date (event-first, Silver fallback) ===== */
portfolio_keys AS (
  SELECT DISTINCT GCID, PortfolioID_EVENT  AS PortfolioID FROM pc_dedup
  UNION
  SELECT DISTINCT GCID, PortfolioID_SILVER AS PortfolioID FROM aum_base
),

portfolio_created_resolved AS (
  SELECT
    k.GCID,
    k.PortfolioID,
    CAST(COALESCE(pc.PortfolioCreatedTs_EVENT, af.FirstAppearance_SILVER) AS DATE) AS PortfolioCreatedDate,
    pc.ProductID_EVENT AS ProductCode,
    mlp.Portfolio_Model_Id_SILVER_LATEST_NONNULL AS Portfolio_Model_Id_Resolved    -- ADDED
  FROM portfolio_keys k
  LEFT JOIN pc_dedup pc
    ON pc.GCID = k.GCID AND pc.PortfolioID_EVENT = k.PortfolioID
  LEFT JOIN aum_first af
    ON af.GCID = k.GCID AND af.PortfolioID_SILVER = k.PortfolioID
  LEFT JOIN aum_model_latest_pick mlp                                                 -- ADDED
    ON mlp.GCID = k.GCID AND mlp.PortfolioID_SILVER = k.PortfolioID
),

portfolio_labeled AS (
  /* Translate product codes to friendly names for slicing. */
  SELECT
    p.GCID,
    p.PortfolioID,
    p.PortfolioCreatedDate,
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
  FROM portfolio_created_resolved p
),

/* USER-level first portfolio created date (across ALL portfolios) */
user_first_portfolio_created_date AS (
  SELECT
    GCID,
    MIN(PortfolioCreatedDate) AS UserFirstPortfolioCreatedDate
  FROM portfolio_labeled
  WHERE PortfolioCreatedDate IS NOT NULL
  GROUP BY GCID
),

/* Representative portfolio on user's first portfolio created date (for product attribution). */
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

/* Registered + global FTD (independent daily events, bounded to output window). */
reg_events AS (
  SELECT
    dc.GCID,
    CAST(dc.RegisteredReal AS DATE) AS RegDate
  FROM main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer dc
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country cu
    ON dc.CountryID = cu.CountryID
  WHERE cu.MarketingRegionManualName = 'UK'
    AND CAST(dc.RegisteredReal AS DATE) >= DATE '2025-01-01'
    AND dc.IsValidCustomer = 1
),

ftd_events AS (
  SELECT
    dc.GCID,
    CAST(dc.FirstDepositDate AS DATE) AS FTDDate
  FROM main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer dc
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country cu
    ON dc.CountryID = cu.CountryID
  WHERE cu.MarketingRegionManualName = 'UK'
    AND DATE_FORMAT(dc.FirstDepositDate, 'yyyy-MM') <> '1900-01'
    AND CAST(dc.FirstDepositDate AS DATE) >= DATE '2025-01-01'
    AND dc.IsValidCustomer = 1
),

/* Accepted TnCs date (existing approach: CreateAccount event if present, else bronze created timestamp). */
bronze_users AS (
  SELECT DISTINCT
    gcid              AS GCID,
    createdAtDateTime AS BronzeCreatedAt
  FROM main.bi_db.bronze_sub_accounts_accounts
  WHERE LOWER(providerName) = 'moneyfarm'
    AND createdAtDateTime < CURRENT_DATE()
    AND CAST(createdAtDateTime AS DATE) >= DATE '2025-01-01'
),

user_createaccount AS (
  SELECT GCID, MIN(CreatedAtTs) AS CreateAccountTs
  FROM base_events
  WHERE EventType = 'CreateAccount'
  GROUP BY GCID
),

accepted_tncs AS (
  SELECT
    u.GCID,
    CAST(COALESCE(ca.CreateAccountTs, bu.BronzeCreatedAt) AS DATE) AS TnCsDate
  FROM (
    SELECT DISTINCT GCID FROM reg_events
    UNION
    SELECT DISTINCT GCID FROM ftd_events
    UNION
    SELECT DISTINCT GCID FROM bronze_users
    UNION
    SELECT DISTINCT GCID FROM base_events
    UNION
    SELECT DISTINCT GCID FROM aum_base
  ) u
  LEFT JOIN user_createaccount ca ON ca.GCID = u.GCID
  LEFT JOIN bronze_users bu       ON bu.GCID = u.GCID
  WHERE COALESCE(ca.CreateAccountTs, bu.BronzeCreatedAt) IS NOT NULL
),

ftd_platform_dict AS (
  SELECT ID, Name
  FROM main.bi_db.bronze_moneybusdb_dictionary_accounttypes
),

/* GCID universe for enrichment — keeps dim_customer lookup scoped to “relevant” users only. */
gcid_universe AS (
  SELECT DISTINCT GCID
  FROM (
    SELECT GCID FROM reg_events
    UNION
    SELECT GCID FROM ftd_events
    UNION
    SELECT GCID FROM accepted_tncs
    UNION
    SELECT GCID FROM user_first_portfolio_created_pick
  ) u
),

/* dim_customer enrichment + affiliate enrichment.
   If affiliate is missing / not mapped, these simply remain NULL (and group as unknown). */
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

/* ===== Denominator: daily regs by dims (product is None here) ===== */
regs_by_dim AS (
  SELECT
    r.RegDate AS EventDate,
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
    COUNT(DISTINCT r.GCID) AS Registered_Users
  FROM reg_events r
  LEFT JOIN dim_customer_lookup d
    ON d.GCID = r.GCID
  GROUP BY
    r.RegDate,
    d.Gender, d.Channel, d.SubChannel,
    d.FTDPlatformID, d.FTDPlatformName,
    d.AffiliateID, d.AffiliatesGroupsName, d.Contact
),

/* ===== Same-day Reg -> FTD (dims from dim_customer; product None) ===== */
same_day_reg_to_ftd AS (
  SELECT
    r.RegDate AS EventDate,
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
    COUNT(DISTINCT r.GCID) AS SameDay_Reg_to_FTD_Users
  FROM reg_events r
  JOIN ftd_events f
    ON f.GCID = r.GCID
   AND f.FTDDate = r.RegDate
  LEFT JOIN dim_customer_lookup d
    ON d.GCID = r.GCID
  GROUP BY
    r.RegDate,
    d.Gender, d.Channel, d.SubChannel,
    d.FTDPlatformID, d.FTDPlatformName,
    d.AffiliateID, d.AffiliatesGroupsName, d.Contact
),

/* ===== Same-day Reg -> AcceptedTnCs (dims from dim_customer; product None) ===== */
same_day_reg_to_tncs AS (
  SELECT
    r.RegDate AS EventDate,
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
    COUNT(DISTINCT r.GCID) AS SameDay_Reg_to_AcceptedTnCs_Users
  FROM reg_events r
  JOIN accepted_tncs t
    ON t.GCID = r.GCID
   AND t.TnCsDate = r.RegDate
  LEFT JOIN dim_customer_lookup d
    ON d.GCID = r.GCID
  GROUP BY
    r.RegDate,
    d.Gender, d.Channel, d.SubChannel,
    d.FTDPlatformID, d.FTDPlatformName,
    d.AffiliateID, d.AffiliatesGroupsName, d.Contact
),

/* ===== Same-day Reg -> FirstPortfolioCreated (product from first-portfolio-created pick) ===== */
same_day_reg_to_first_portfolio_created AS (
  SELECT
    r.RegDate AS EventDate,
    d.Gender,
    d.Channel,
    d.SubChannel,
    COALESCE(p.ProductName_Code, 'None') AS ProductName_Code,
    COALESCE(p.ProductName, 'None')      AS ProductName,
    d.FTDPlatformID,
    d.FTDPlatformName,
    d.AffiliateID,
    d.AffiliatesGroupsName,
    d.Contact,
    COUNT(DISTINCT r.GCID) AS SameDay_Reg_to_FirstPortfolioCreated_Users
  FROM reg_events r
  JOIN user_first_portfolio_created_pick p
    ON p.GCID = r.GCID
   AND p.PortfolioCreatedDate = r.RegDate
  LEFT JOIN dim_customer_lookup d
    ON d.GCID = r.GCID
  GROUP BY
    r.RegDate,
    d.Gender, d.Channel, d.SubChannel,
    COALESCE(p.ProductName_Code, 'None'),
    COALESCE(p.ProductName, 'None'),
    d.FTDPlatformID, d.FTDPlatformName,
    d.AffiliateID, d.AffiliatesGroupsName, d.Contact
),

/* Date/dim spine so we can left join the three same-day metrics to the reg denominator.
   We include the product-bearing spine from the FirstPortfolioCreated conversion so those rows show up. */
spine AS (
  SELECT
    EventDate,
    Gender, Channel, SubChannel,
    ProductName_Code, ProductName,
    FTDPlatformID, FTDPlatformName,
    AffiliateID, AffiliatesGroupsName, Contact
  FROM regs_by_dim

  UNION

  SELECT
    EventDate,
    Gender, Channel, SubChannel,
    ProductName_Code, ProductName,
    FTDPlatformID, FTDPlatformName,
    AffiliateID, AffiliatesGroupsName, Contact
  FROM same_day_reg_to_first_portfolio_created
)

SELECT
  s.EventDate,

  s.Gender,
  s.Channel,
  s.SubChannel,

  s.ProductName_Code,
  s.ProductName,

  s.FTDPlatformID,
  s.FTDPlatformName,

  s.AffiliateID,
  s.AffiliatesGroupsName,
  s.Contact,

  COALESCE(r.Registered_Users, 0) AS Registered_Users,

  COALESCE(f.SameDay_Reg_to_FTD_Users, 0) AS SameDay_Reg_to_FTD_Users,
  COALESCE(t.SameDay_Reg_to_AcceptedTnCs_Users, 0) AS SameDay_Reg_to_AcceptedTnCs_Users,
  COALESCE(p.SameDay_Reg_to_FirstPortfolioCreated_Users, 0) AS SameDay_Reg_to_FirstPortfolioCreated_Users

  -- CASE WHEN COALESCE(r.Registered_Users, 0) = 0 THEN NULL
  --      ELSE (COALESCE(f.SameDay_Reg_to_FTD_Users, 0) * 1.0) / COALESCE(r.Registered_Users, 0) END
  --      AS SameDay_Reg_to_FTD_Rate,

  -- CASE WHEN COALESCE(r.Registered_Users, 0) = 0 THEN NULL
  --      ELSE (COALESCE(t.SameDay_Reg_to_AcceptedTnCs_Users, 0) * 1.0) / COALESCE(r.Registered_Users, 0) END
  --      AS SameDay_Reg_to_AcceptedTnCs_Rate,

  -- CASE WHEN COALESCE(r.Registered_Users, 0) = 0 THEN NULL
  --      ELSE (COALESCE(p.SameDay_Reg_to_FirstPortfolioCreated_Users, 0) * 1.0) / COALESCE(r.Registered_Users, 0) END
  --      AS SameDay_Reg_to_FirstPortfolioCreated_Rate

FROM spine s
LEFT JOIN regs_by_dim r
  ON  r.EventDate = s.EventDate
  AND r.Gender <=> s.Gender
  AND r.Channel <=> s.Channel
  AND r.SubChannel <=> s.SubChannel
  AND r.ProductName_Code <=> s.ProductName_Code
  AND r.ProductName <=> s.ProductName
  AND r.FTDPlatformID <=> s.FTDPlatformID
  AND r.FTDPlatformName <=> s.FTDPlatformName
  AND r.AffiliateID <=> s.AffiliateID
  AND r.AffiliatesGroupsName <=> s.AffiliatesGroupsName
  AND r.Contact <=> s.Contact

LEFT JOIN same_day_reg_to_ftd f
  ON  f.EventDate = s.EventDate
  AND f.Gender <=> s.Gender
  AND f.Channel <=> s.Channel
  AND f.SubChannel <=> s.SubChannel
  AND f.ProductName_Code <=> s.ProductName_Code
  AND f.ProductName <=> s.ProductName
  AND f.FTDPlatformID <=> s.FTDPlatformID
  AND f.FTDPlatformName <=> s.FTDPlatformName
  AND f.AffiliateID <=> s.AffiliateID
  AND f.AffiliatesGroupsName <=> s.AffiliatesGroupsName
  AND f.Contact <=> s.Contact

LEFT JOIN same_day_reg_to_tncs t
  ON  t.EventDate = s.EventDate
  AND t.Gender <=> s.Gender
  AND t.Channel <=> s.Channel
  AND t.SubChannel <=> s.SubChannel
  AND t.ProductName_Code <=> s.ProductName_Code
  AND t.ProductName <=> s.ProductName
  AND t.FTDPlatformID <=> s.FTDPlatformID
  AND t.FTDPlatformName <=> s.FTDPlatformName
  AND t.AffiliateID <=> s.AffiliateID
  AND t.AffiliatesGroupsName <=> s.AffiliatesGroupsName
  AND t.Contact <=> s.Contact

LEFT JOIN same_day_reg_to_first_portfolio_created p
  ON  p.EventDate = s.EventDate
  AND p.Gender <=> s.Gender
  AND p.Channel <=> s.Channel
  AND p.SubChannel <=> s.SubChannel
  AND p.ProductName_Code <=> s.ProductName_Code
  AND p.ProductName <=> s.ProductName
  AND p.FTDPlatformID <=> s.FTDPlatformID
  AND p.FTDPlatformName <=> s.FTDPlatformName
  AND p.AffiliateID <=> s.AffiliateID
  AND p.AffiliatesGroupsName <=> s.AffiliatesGroupsName
  AND p.Contact <=> s.Contact

WHERE s.EventDate >= DATE '2025-01-01'