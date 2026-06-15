/* ======================
   Silver-first portfolio panel with events (up to yesterday) as enrich/backfill
   Grain: GCID × PortfolioID (only portfolios present in Silver AUM)
   Adds funding/defunding flags + manager/club at First Deposit (FTF)
   Also adds contact flags for activity in the 30d window up to (and including) each portfolio’s FTF date:
     - any qualifying contact
     - contacted by AM at FTF
     - contacted by current AM
   ====================== */

/* 1) Begin with raw Silver AUM data & parse SourceFile timestamp for later deduplication
      (as there are sometimes instances of "double sends" on one day creating two rows, so taking the row with the most recent SourceFile)
      --- SourceFile string example: ETORO-MF-AUM-20251125T0539_V1.CSV
      - Extract the embedded YYYYMMDDTHHMM pattern from SourceFile (e.g. '20251125T0539')
      - Convert that into a proper timestamp so we can pick the *latest* file per day/GCID/portfolio
*/
WITH aum_raw AS (
  SELECT
      GCID,
      Identifier_Value,
      Portfolio_Id,
      CAST(etr_ymd AS DATE) AS etr_ymd,
      Product,
      Portfolio_Model_Id,           -- ADDED
      Market_Value,
      Total_Investments,
      Total_Disinvestments,
      SourceFile,

      -- Grab the first occurrence of 8 digits, 'T', then 4 digits (e.g. '20251125T0539') from the SourceFile string
      REGEXP_EXTRACT(SourceFile, '(\\d{8}T\\d{4})', 1) AS sf_ts_raw,

      -- If we successfully extracted a YYYYMMDDTHHMM string, strip out the 'T' and turn it into a timestamp
      CASE
        WHEN REGEXP_EXTRACT(SourceFile, '(\\d{8}T\\d{4})', 1) IS NOT NULL
          THEN TO_TIMESTAMP(REPLACE(REGEXP_EXTRACT(SourceFile, '(\\d{8}T\\d{4})', 1), 'T', ''), 'yyyyMMddHHmm')
        ELSE NULL
      END AS sf_ts
  FROM money_farm.silver_moneyfarm_etoro_mf_aum
),

/* 2) Dedupe daily snapshots: prefer rows with SourceFile, then latest embedded timestamp
      (due to SourceFile only being present for some of the data, and sometimes there are duplicates rows with source files that have different timestamps.
      Take the row with the sourcefile with the later timestamp.
      In the instances where there is no sourcefile data for earlier periods of existing users, take just one of the rows (if there are duplicates in a day)
      as these are often just pure duplicates)
*/
aum_dedup AS (
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

/* 3) Normalise numeric fields & product text */
aum_base AS (
  SELECT
      GCID,
      Portfolio_Id                                     AS PortfolioID_SILVER,
      etr_ymd                                          AS etr_ymd,
      Product                                          AS Product_SILVER_RAW,
      NULLIF(TRIM(Product), '')                        AS Product_SILVER_NORM,
      NULLIF(TRIM(CAST(Portfolio_Model_Id AS STRING)), '') AS Portfolio_Model_Id_SILVER_NORM,   -- ADDED
      TRY_CAST(Market_Value AS DECIMAL(18,2))          AS Market_Value_SILVER,
      TRY_CAST(Total_Investments AS DECIMAL(18,2))     AS Total_Investments_SILVER,
      TRY_CAST(Total_Disinvestments AS DECIMAL(18,2))  AS Total_Disinvestments_SILVER
  FROM aum_dedup
),

/* 4) Portfolio keys present in Silver */
aum_keys AS (
  SELECT DISTINCT GCID, PortfolioID_SILVER
  FROM aum_base
),

/* 5) First appearance of the portfolio in Silver (used as backfill for PORTFOLIO_CREATED date in absence of an event)
      (Due PORTFOLIO_CREATED events only being introduced at a later date, therefore the appearance in silver for a portfolio is the "next best" representation)
*/
aum_first AS (
  SELECT
      GCID,
      PortfolioID_SILVER,
      MIN(etr_ymd) AS FirstAppearance_SILVER
  FROM aum_base
  GROUP BY GCID, PortfolioID_SILVER
),

/* 6) Resolve product from Silver: earliest non-blank; fallback to latest non-blank
      (Due to there being many rows in the data table that dont have a product (null) as it was only integrated at a later date)
*/
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

/* 6b) Resolve Portfolio_Model_Id from Silver: latest non-blank (per portfolio)
       (Model id may be missing historically; we use the latest known model id for labeling such as Cash ISA V2)
*/
aum_model_latest_nonblank AS (
  SELECT GCID, PortfolioID_SILVER, MAX(etr_ymd) AS latest_model_ymd
  FROM aum_base
  WHERE Portfolio_Model_Id_SILVER_NORM IS NOT NULL
  GROUP BY GCID, PortfolioID_SILVER
),
aum_model_latest_pick AS (
  SELECT b.GCID, b.PortfolioID_SILVER, b.Portfolio_Model_Id_SILVER_NORM AS Portfolio_Model_Id_SILVER_LATEST_NONNULL
  FROM aum_base b
  JOIN aum_model_latest_nonblank m
    ON  b.GCID = m.GCID
    AND b.PortfolioID_SILVER = m.PortfolioID_SILVER
    AND b.etr_ymd = m.latest_model_ymd
),

/* 7) First date cumulative Total_Investments > 0 (Silver_AUM data used as backfill for first deposit) */
aum_first_ti_positive AS (
  SELECT t.GCID, t.PortfolioID_SILVER, MIN(t.etr_ymd) AS FirstTIPosDate_SILVER
  FROM aum_base t
  WHERE t.Total_Investments_SILVER > 0
  GROUP BY t.GCID, t.PortfolioID_SILVER
),
aum_first_ti_amount AS (
  SELECT p.GCID, p.PortfolioID_SILVER, p.FirstTIPosDate_SILVER,
         x.Total_Investments_SILVER AS FirstTIPosAmount_SILVER
  FROM aum_first_ti_positive p
  JOIN aum_base x
    ON x.GCID = p.GCID
   AND x.PortfolioID_SILVER = p.PortfolioID_SILVER
   AND x.etr_ymd = p.FirstTIPosDate_SILVER
),

/* 8) Latest available Silver snapshot for current status flags */
aum_latest AS (
  SELECT *
  FROM (
    SELECT
      GCID,
      PortfolioID_SILVER,
      etr_ymd                                  AS Latest_Snapshot_Date_SILVER,
      Market_Value_SILVER                      AS Latest_Market_Value_GBP_SILVER,
      Total_Investments_SILVER                 AS Latest_Total_Investments_GBP_SILVER,
      Total_Disinvestments_SILVER              AS Latest_Total_Disinvestments_GBP_SILVER,
      ROW_NUMBER() OVER (
        PARTITION BY GCID, PortfolioID_SILVER
        ORDER BY etr_ymd DESC
      ) AS rn_latest
    FROM aum_base
  ) x
  WHERE rn_latest = 1
),

/* 9) Full Event stream (limited to events from yesterday and before, so not to take events that have fired on the day the query running) */
base_events AS (
  SELECT
      EventPayloadRowData_EventMetadata_Gcid                    AS GCID,
      EventPayloadRowData_EventMetadata_EventType               AS EventType,
      to_timestamp(EventPayloadRowData_EventMetadata_CreatedAt) AS CreatedAtTs,
      EventPayloadRowData_EventData                             AS EventDataStr
  FROM main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts
  WHERE EventPayloadRowData_ProviderName = 'Moneyfarm'
    AND to_timestamp(EventPayloadRowData_EventMetadata_CreatedAt) < current_date()
),
with_data_outer AS (
  SELECT b.*, from_json(b.EventDataStr, 'STRUCT<data STRING>') AS outer_obj
  FROM base_events b
),

/* 10) Portfolio created (dedup per GCID×Portfolio) as there are instances of the event double firing */
pc_raw AS (
  SELECT GCID, CreatedAtTs,
         from_json(outer_obj.data, 'STRUCT<portfolioId STRING, productId STRING>') AS inner_pc
  FROM with_data_outer
  WHERE EventType = 'PORTFOLIO_CREATED'
),
pc_norm AS (
  SELECT GCID,
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
      MIN(CreatedAtTs)            OVER (PARTITION BY GCID, PortfolioID_EVENT)                           AS PortfolioCreatedDate_EVENT
  FROM pc_norm
),
pc_dedup AS (
  SELECT DISTINCT GCID, PortfolioID_EVENT, ProductID_EVENT, PortfolioCreatedDate_EVENT
  FROM pc_first
),

/* 11) First deposit event per portfolio (up to yesterday) + presence of pd event (not necessarily the first deposit of that portfolio) */
pd_raw AS (
  SELECT GCID, CreatedAtTs,
         from_json(outer_obj.data, 'STRUCT<portfolioId STRING, amount STRING, currency STRING, valueDate STRING>') AS inner_pd
  FROM with_data_outer
  WHERE EventType = 'PORTFOLIO_DEPOSIT'
),
pd_norm AS (
  SELECT
      GCID,
      inner_pd.portfolioId                        AS PortfolioID_EVENT,
      CreatedAtTs                                 AS DepositCreatedAtTs_EVENT,
      TRY_CAST(inner_pd.amount AS DECIMAL(18,2))  AS DepositAmount_EVENT,
      inner_pd.currency                           AS DepositCurrency_EVENT
  FROM pd_raw
  WHERE inner_pd.portfolioId IS NOT NULL
),
pd_first AS (
  SELECT *
  FROM (
    SELECT
        GCID,
        PortfolioID_EVENT,
        DepositCreatedAtTs_EVENT,
        DepositAmount_EVENT,
        DepositCurrency_EVENT,
        ROW_NUMBER() OVER (PARTITION BY GCID, PortfolioID_EVENT ORDER BY DepositCreatedAtTs_EVENT ASC) AS rn
    FROM pd_norm
  ) x
  WHERE rn = 1
),
pd_exists AS (
  SELECT DISTINCT GCID, PortfolioID_EVENT
  FROM pd_norm
),

/* 12) Emptied events + check if any deposit followed the last empty (to help assess if still empty or not)*/
pe_raw AS (
  SELECT GCID, CreatedAtTs,
         from_json(outer_obj.data, 'STRUCT<portfolioId STRING>') AS inner_pe
  FROM with_data_outer
  WHERE EventType = 'PORTFOLIO_EMPTIED'
),
pe_norm AS (
  SELECT GCID, inner_pe.portfolioId AS PortfolioID_EVENT, CreatedAtTs AS EmptiedAtTs_EVENT
  FROM pe_raw
  WHERE inner_pe.portfolioId IS NOT NULL
),
pe_last AS (
  SELECT GCID, PortfolioID_EVENT, MAX(EmptiedAtTs_Event) AS LastEmptiedAtTs_EVENT
  FROM pe_norm
  GROUP BY GCID, PortfolioID_EVENT
),
deposit_after_emptied AS (
  SELECT
    e.GCID,
    e.PortfolioID_EVENT,
    CASE WHEN MAX(CASE WHEN p.DepositCreatedAtTs_EVENT > e.LastEmptiedAtTs_EVENT THEN 1 ELSE 0 END) = 1
         THEN 1 ELSE 0 END AS HasDepositAfterEmpty
  FROM pe_last e
  LEFT JOIN pd_norm p
    ON p.GCID = e.GCID
   AND p.PortfolioID_EVENT = e.PortfolioID_EVENT
  GROUP BY e.GCID, e.PortfolioID_EVENT
),

/* 13) current AM & current club level
      - Keep the internal ManagerID (AccountManagerID) for comparisons to AM-at-FTF and mapped CRM contacts
*/
user_info AS (
  SELECT
    dc.GCID,
    CAST(dc.RealCID AS STRING)             AS CID,
    dc.AccountManagerID                    AS account_manager_id_now,
    CONCAT(dm.FirstName, ' ', dm.LastName) AS account_manager,
    pl.Name                                AS club_level
  FROM main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer dc
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm
    ON dc.AccountManagerID = dm.ManagerID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl
    ON dc.PlayerLevelID = pl.PlayerLevelID
),

/* 14) Assemble: decide created date, first deposit (event when reliable, else Silver), resolve product + model id */
assembled AS (
  SELECT
      k.GCID,
      k.PortfolioID_SILVER                         AS PortfolioID,

      COALESCE(pc.PortfolioCreatedDate_EVENT, af.FirstAppearance_SILVER) AS PortfolioCreatedDate,
      CASE WHEN pc.PortfolioCreatedDate_EVENT IS NOT NULL THEN 'EVENT'
           WHEN af.FirstAppearance_SILVER IS NOT NULL THEN 'SILVER_BACKFILL'
           ELSE NULL END AS PortfolioCreatedDate_Source,

      CASE
        WHEN pc.PortfolioID_EVENT IS NOT NULL AND pf.DepositCreatedAtTs_EVENT IS NOT NULL
          THEN pf.DepositCreatedAtTs_EVENT
        ELSE ati.FirstTIPosDate_SILVER
      END AS FirstDepositDate,
      CASE
        WHEN pc.PortfolioID_EVENT IS NOT NULL AND pf.DepositCreatedAtTs_EVENT IS NOT NULL
          THEN pf.DepositAmount_EVENT
        ELSE atia.FirstTIPosAmount_SILVER
      END AS FirstDepositAmount,
      CASE
        WHEN pc.PortfolioID_EVENT IS NOT NULL AND pf.DepositCreatedAtTs_EVENT IS NOT NULL
          THEN 'EVENT'
        WHEN ati.FirstTIPosDate_SILVER IS NOT NULL
          THEN 'SILVER_BACKFILL'
        ELSE NULL
      END AS FirstDeposit_Source,

      COALESCE(pc.ProductID_EVENT, apr.Product_SILVER_RESOLVED) AS Product_Resolved,

      mlp.Portfolio_Model_Id_SILVER_LATEST_NONNULL AS Portfolio_Model_Id_Resolved   -- ADDED
  FROM aum_keys k
  LEFT JOIN aum_first                af   ON af.GCID = k.GCID AND af.PortfolioID_SILVER = k.PortfolioID_SILVER
  LEFT JOIN aum_product_resolved     apr  ON apr.GCID = k.GCID AND apr.PortfolioID_SILVER = k.PortfolioID_SILVER
  LEFT JOIN aum_model_latest_pick    mlp  ON mlp.GCID = k.GCID AND mlp.PortfolioID_SILVER = k.PortfolioID_SILVER   -- ADDED
  LEFT JOIN aum_first_ti_positive    ati  ON ati.GCID = k.GCID AND ati.PortfolioID_SILVER = k.PortfolioID_SILVER
  LEFT JOIN aum_first_ti_amount      atia ON atia.GCID = k.GCID AND atia.PortfolioID_SILVER = k.PortfolioID_SILVER
  LEFT JOIN pc_dedup pc
    ON pc.GCID = k.GCID
   AND pc.PortfolioID_EVENT = k.PortfolioID_SILVER
  LEFT JOIN pd_first pf
    ON pf.GCID = k.GCID
   AND pf.PortfolioID_EVENT = k.PortfolioID_SILVER
),

/* 15) readable product label */
labeled AS (
  SELECT
    a.*,
    CASE
      WHEN LOWER(a.Product_Resolved) = 'isa-cash'
       AND LOWER(a.Portfolio_Model_Id_Resolved) = 'etoro-gb-r0-c1-cash-saving-account-v2'
        THEN 'Cash ISA - V2'
      ELSE
        CASE LOWER(a.Product_Resolved)
          WHEN 'isa-discretionary'      THEN 'Managed ISA'
          WHEN 'gia-discretionary'      THEN 'Managed General Investment Account'
          WHEN 'jisa-discretionary'     THEN 'Managed Junior ISA'
          WHEN 'sipp-discretionary'     THEN 'Managed Self-Invested Personal Pension'
          WHEN 'gia-execution-only'     THEN 'DIY General Investment Account'
          WHEN 'isa-execution-only'     THEN 'DIY ISA'
          WHEN 'jisa-execution-only'    THEN 'DIY Junior ISA'
          WHEN 'isa-cash'               THEN 'Cash ISA'
          ELSE a.Product_Resolved
        END
    END AS ProductName
  FROM assembled a
),

/* 16) AM & Club Level at FTF — PER-PORTFOLIO
       - Only evaluates GCID/Portfolio pairs that actually have an FTF date
*/
fscdr AS (
  SELECT
    f.GCID,
    ftf.PortfolioID,
    f.AccountManagerID AS AccountManagerID,
    f.PlayerLevelID    AS PlayerLevelID
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked f
  JOIN (
    SELECT DISTINCT
      l.GCID,
      l.PortfolioID,
      CAST(date_format(l.FirstDepositDate, 'yyyyMMdd') AS INT) AS FTF_INT
    FROM labeled l
    WHERE l.FirstDepositDate IS NOT NULL
  ) ftf
    ON ftf.GCID = f.GCID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
    ON f.DateRangeID = dr.DateRangeID
   AND ftf.FTF_INT BETWEEN dr.FromDateID AND dr.ToDateID
),

/* 17) Build per-portfolio FTF windows [FTF-30, FTF] (inclusive)
       - Grain: GCID × PortfolioID
       - This handles different portfolios having different FTF dates
*/
ftf_windows AS (
  SELECT
    l.GCID,
    p.CID,
    l.PortfolioID,
    CAST(l.FirstDepositDate AS DATE) AS FTF_Date,
    date_sub(CAST(l.FirstDepositDate AS DATE), 30) AS FTF_StartDate
  FROM labeled l
  JOIN user_info p
    ON p.GCID = l.GCID
  WHERE l.FirstDepositDate IS NOT NULL
),

/* 18) Pull contact superset for a fixed bounded range (hard-coded earliest bound)
       - Earliest bound hard-coded: '2023-04-05' (30d prior to earliest FTF)
       - Latest bound: yesterday ("up to yesterday")
       - Join CRM AccountManagerId (Salesforce id) to dim_manager.SFManagerID to obtain the internal ManagerID for matching.
         Use LEFT JOIN so "any contact" remains truly any contact even if AccountManagerId is missing/unmapped.
*/
crm_contacts_superset AS (
  SELECT
    CAST(c.CID AS STRING)           AS CID,
    CAST(c.CreatedDate AS DATE)     AS ContactDate,
    dm.ManagerID                    AS ContactManagerID
  FROM main.bi_output.tf_crm_contact_user(
    DATE '2023-04-05',
    date_sub(current_date(), 1)
  ) c
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm
    ON dm.SFManagerID = c.AccountManagerId
  WHERE LOWER(TRIM(c.CF_Terminology)) IN ('zoom','completed phone','whatsapp','completed email')
),

/* 19) Apply per-portfolio window filter: ContactDate BETWEEN (FTF-30) AND FTF (inclusive) */
contacts_window_rows AS (
  SELECT
    w.GCID,
    w.CID,
    w.PortfolioID,
    c.ContactDate,
    c.ContactManagerID
  FROM ftf_windows w
  LEFT JOIN crm_contacts_superset c
    ON c.CID = w.CID
   AND c.ContactDate BETWEEN w.FTF_StartDate AND w.FTF_Date
),

/* 20) Aggregate to portfolio grain and compute flags:
       - HasAnyContact_30d: any qualifying contact in the window regardless of whether the manager id was mapped
       - ContactedBy_AM_at_FTF_in_30d: contact mapped ManagerID equals AM-at-FTF ManagerID
       - ContactedBy_CurrentAM_in_30d: contact mapped ManagerID equals current AM ManagerID
*/
contacts_flags AS (
  SELECT
    r.GCID,
    r.PortfolioID,

    MAX(CASE WHEN r.ContactDate IS NOT NULL THEN 1 ELSE 0 END) AS HasAnyContact_30d,

    MAX(CASE
          WHEN r.ContactManagerID IS NOT NULL
           AND r.ContactManagerID = f.AccountManagerID
          THEN 1 ELSE 0
        END) AS ContactedBy_AM_at_FTF_in_30d,

    MAX(CASE
          WHEN r.ContactManagerID IS NOT NULL
           AND r.ContactManagerID = p.account_manager_id_now
          THEN 1 ELSE 0
        END) AS ContactedBy_CurrentAM_in_30d

  FROM contacts_window_rows r
  JOIN user_info p
    ON p.GCID = r.GCID
  LEFT JOIN fscdr f
    ON f.GCID = r.GCID
   AND f.PortfolioID = r.PortfolioID
  GROUP BY r.GCID, r.PortfolioID
)

/* =================== FINAL =================== */
SELECT
  l.GCID,
  p.CID,
  l.PortfolioID,
  l.Product_Resolved              AS ProductName_Code,
  l.ProductName,

  /* current user attributes (repeat per portfolio row) */
  p.account_manager               AS account_manager_now,
  p.club_level                    AS club_level_now,

  /* AM/club level at the portfolio's own FTF (NULL if no FTF for that portfolio) */
  CONCAT(dm_ftf.FirstName, ' ', dm_ftf.LastName) AS account_manager_at_FTF,
  pl_ftf.Name                                   AS club_level_at_FTF,

  /* portfolio related */
  CAST(l.PortfolioCreatedDate AS DATE)          AS PortfolioCreatedDate,
  l.PortfolioCreatedDate_Source,
  CAST(l.FirstDepositDate AS DATE)              AS FirstDepositDate,
  l.FirstDepositAmount,
  l.FirstDeposit_Source,

  /* latest Silver snapshot */
  al.Latest_Snapshot_Date_SILVER,
  al.Latest_Market_Value_GBP_SILVER,
  al.Latest_Total_Investments_GBP_SILVER,
  al.Latest_Total_Disinvestments_GBP_SILVER,

  /* funding flags */
  CASE WHEN al.Latest_Market_Value_GBP_SILVER > 0 THEN 1 ELSE 0 END AS PortfolioIsFunded,
  CASE WHEN al.Latest_Total_Investments_GBP_SILVER > 0 THEN 1 ELSE 0 END AS PortfolioHasEverBeenFunded,

  /* defunded flag: (has ever been funded OR any deposit event exists) AND (MV=0 OR emptied with no re-deposit) */
  CASE
    WHEN
      (
        (al.Latest_Total_Investments_GBP_SILVER > 0) OR
        (pd.PortfolioID_EVENT IS NOT NULL)
      )
      AND
      (
        (COALESCE(al.Latest_Market_Value_GBP_SILVER, 0) = 0) OR
        (pel.LastEmptiedAtTs_EVENT IS NOT NULL AND COALESCE(da.HasDepositAfterEmpty, 0) = 0)
      )
    THEN 1 ELSE 0
  END AS PortfolioDefunded,

  /* contact flags: checker + AM-matched contact flags (ID-based matching via dim_manager.SFManagerID ⇢ ManagerID) */
  COALESCE(cf.HasAnyContact_30d, 0) AS HasAnyContact_30d,
  CASE WHEN COALESCE(cf.ContactedBy_AM_at_FTF_in_30d, 0) = 1 THEN 'yes' ELSE 'no' END
    AS ContactedBy_AM_at_FTF_in_30d,
  CASE WHEN COALESCE(cf.ContactedBy_CurrentAM_in_30d, 0) = 1 THEN 'yes' ELSE 'no' END
    AS ContactedBy_CurrentAM_in_30d

FROM labeled l
LEFT JOIN user_info p
  ON p.GCID = l.GCID
LEFT JOIN aum_latest al
  ON al.GCID = l.GCID
 AND al.PortfolioID_SILVER = l.PortfolioID
LEFT JOIN pd_exists pd
  ON pd.GCID = l.GCID
 AND pd.PortfolioID_EVENT = l.PortfolioID
LEFT JOIN pe_last pel
  ON pel.GCID = l.GCID
 AND pel.PortfolioID_EVENT = l.PortfolioID
LEFT JOIN deposit_after_emptied da
  ON da.GCID = l.GCID
 AND da.PortfolioID_EVENT = l.PortfolioID

/* AM & Club Level at FTF — PER-PORTFOLIO */
LEFT JOIN fscdr fscdr
  ON fscdr.GCID = l.GCID
 AND fscdr.PortfolioID = l.PortfolioID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm_ftf
  ON fscdr.AccountManagerID = dm_ftf.ManagerID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl_ftf
  ON fscdr.PlayerLevelID = pl_ftf.PlayerLevelID

/* portfolio-grain contact flags */
LEFT JOIN contacts_flags cf
  ON cf.GCID = l.GCID
 AND cf.PortfolioID = l.PortfolioID

/* optional scope limiter for testing */
--WHERE l.GCID IN (558985, 10208, 690408, 848474)

ORDER BY l.GCID, l.PortfolioID