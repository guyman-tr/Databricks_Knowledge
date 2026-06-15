/* ============================================================
   UK Funded Users: eToro (Daily Status) vs MF classification
   Uses Customer Daily Status IsFunded at EOM / latest available day
   + Moneyfarm Silver AUM for MF funded
   3 pots: Funded only outside MF | MoneyFarm Funded Only | Funded in both
   ============================================================ */

WITH params AS (
  SELECT
    'UK'                          AS region_name,
    /* Use the latest available date in daily status instead of yesterday,
       so the query still works even if yesterday's data hasn't landed yet */
    to_date(
      CAST(
        (SELECT MAX(DateID)
         FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
         WHERE DateID <= CAST(date_format(date_add(current_date(), -1), 'yyyyMMdd') AS INT)
        ) AS STRING
      ), 'yyyyMMdd'
    )                             AS asof_date,
    to_date('2025-01-01')         AS start_month,
    7                             AS lookback_days
),

/* ---------- Monthly snapshots: EOM or latest available for current month ---------- */
snapshots AS (
  SELECT
    month_start,
    CASE
      WHEN last_day(month_start) > p.asof_date THEN p.asof_date
      ELSE last_day(month_start)
    END AS SnapshotDate
  FROM params p
  LATERAL VIEW explode(
    sequence(p.start_month, trunc(p.asof_date, 'MM'), interval 1 month)
  ) s AS month_start
),

/* ---------- eToro funded users from Customer Daily Status on SnapshotDate ---------- */
main_funded AS (
  SELECT DISTINCT
    s.month_start,
    cds.RealCID,
    dc.GCID,
    c.Name          AS Country,
    c.MarketingRegionManualName AS Region
  FROM snapshots s
  JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status cds
    ON cds.DateID = CAST(date_format(s.SnapshotDate, 'yyyyMMdd') AS INT)
   AND cds.IsFunded = 1
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    ON dc.RealCID = cds.RealCID
   AND dc.IsValidCustomer = 1
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country c
    ON c.CountryID = dc.CountryID
  JOIN params p
    ON c.MarketingRegionManualName = p.region_name
),

/* ---------- MF Silver raw + RealCID/GCID mapping ---------- */
aum_raw AS (
  SELECT
    mf.GCID,
    dc.RealCID,
    c.Name          AS Country,
    c.MarketingRegionManualName AS Region,
    mf.Identifier_Value,
    mf.Portfolio_Id,
    CAST(mf.etr_ymd AS DATE) AS etr_ymd,
    TRY_CAST(mf.Market_Value AS DECIMAL(18,2)) AS Market_Value_SILVER,
    mf.SourceFile,
    CASE
      WHEN REGEXP_EXTRACT(mf.SourceFile, '(\\d{8}T\\d{4})', 1) IS NOT NULL
        THEN TO_TIMESTAMP(
               REPLACE(REGEXP_EXTRACT(mf.SourceFile, '(\\d{8}T\\d{4})', 1), 'T', ''),
               'yyyyMMddHHmm'
             )
      ELSE NULL
    END AS sf_ts
  FROM main.money_farm.silver_moneyfarm_etoro_mf_aum mf
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    ON dc.GCID = mf.GCID
   AND dc.IsValidCustomer = 1
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country c
    ON c.CountryID = dc.CountryID
  WHERE CAST(mf.etr_ymd AS DATE) >= (SELECT start_month FROM params)
    AND c.MarketingRegionManualName = (SELECT region_name FROM params)
),

/* Silver dedupe: prefer SourceFile presence, then latest embedded timestamp */
aum_dedup AS (
  SELECT * FROM (
    SELECT r.*,
      ROW_NUMBER() OVER (
        PARTITION BY r.GCID, r.Identifier_Value, r.Portfolio_Id, r.etr_ymd
        ORDER BY
          CASE WHEN r.SourceFile IS NOT NULL THEN 1 ELSE 0 END DESC,
          r.sf_ts DESC NULLS LAST
      ) AS rn
    FROM aum_raw r
  ) x WHERE rn = 1
),

/* ---------- MF snapshot date per month: use SnapshotDate if exists in Silver, else fallback ---------- */
mf_candidates AS (
  SELECT
    s.month_start,
    s.SnapshotDate AS target_date,
    date_sub(s.SnapshotDate, k) AS candidate_date
  FROM snapshots s
  CROSS JOIN (
    SELECT explode(sequence(0, (SELECT lookback_days FROM params))) AS k
  )
),

mf_available AS (
  SELECT
    c.month_start,
    c.candidate_date,
    ROW_NUMBER() OVER (
      PARTITION BY c.month_start
      ORDER BY c.candidate_date DESC
    ) AS rn
  FROM mf_candidates c
  JOIN aum_dedup d ON d.etr_ymd = c.candidate_date
  GROUP BY c.month_start, c.candidate_date
),

mf_snapshot_per_month AS (
  SELECT month_start, candidate_date AS mf_snapshot_date
  FROM mf_available
  WHERE rn = 1
),

/* ---------- MF funded users on MF snapshot date (fallback-aware) ---------- */
mf_funded AS (
  SELECT DISTINCT
    m.month_start,
    d.RealCID,
    d.GCID,
    d.Country,
    d.Region
  FROM mf_snapshot_per_month m
  JOIN aum_dedup d ON d.etr_ymd = m.mf_snapshot_date
  WHERE d.Market_Value_SILVER > 0.00
),

/* ---------- Classify per month + RealCID ---------- */
classified AS (
  SELECT
    COALESCE(mp.month_start, mf.month_start) AS month_start,
    COALESCE(mp.Country, mf.Country)         AS Country,
    COALESCE(mp.Region,  mf.Region)          AS Region,
    COALESCE(mp.RealCID, mf.RealCID)         AS RealCID,
    CASE
      WHEN mp.RealCID IS NOT NULL AND mf.RealCID IS NULL  THEN 'Funded only outside MF'
      WHEN mp.RealCID IS NULL     AND mf.RealCID IS NOT NULL THEN 'MoneyFarm Funded Only'
      WHEN mp.RealCID IS NOT NULL AND mf.RealCID IS NOT NULL THEN 'Funded in both'
    END AS Funded_Specification
  FROM main_funded mp
  FULL OUTER JOIN mf_funded mf
    ON mp.month_start = mf.month_start
   AND mp.RealCID     = mf.RealCID
)

SELECT
  date_format(month_start, 'yyyy-MM') AS `End of Month`,
  Country,
  Region,
  Funded_Specification AS `Funded Specification`,
  COUNT(DISTINCT RealCID) AS `Funded Users`
FROM classified
WHERE Funded_Specification IS NOT NULL
GROUP BY
  date_format(month_start, 'yyyy-MM'),
  Country,
  Region,
  Funded_Specification
ORDER BY
  `End of Month`,
  Country,
  `Funded Specification`