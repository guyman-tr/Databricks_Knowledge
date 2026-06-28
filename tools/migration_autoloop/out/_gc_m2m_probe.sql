WITH ext AS (
  SELECT * FROM dwh_daily_process.migration_tables.Ext_FGC_Guru_Copiers WHERE DateID = 20260622
),
agg_gold_m2m AS (
  SELECT COUNT(DISTINCT g.CID) AS cids
  FROM ext g
  JOIN dwh_daily_process.migration_tables.fact_snapshotcustomer fsc
    ON g.ParentCID = fsc.RealCID AND fsc.AccountTypeID = 9
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_m2m_date_daterange bb
    ON fsc.DateRangeID = bb.DateRangeID AND g.DateID = bb.DateKey
),
agg_mig_m2m AS (
  SELECT COUNT(DISTINCT g.CID) AS cids
  FROM ext g
  JOIN dwh_daily_process.migration_tables.fact_snapshotcustomer fsc
    ON g.ParentCID = fsc.RealCID AND fsc.AccountTypeID = 9
  JOIN dwh_daily_process.migration_tables.V_M2M_Date_DateRange bb
    ON fsc.DateRangeID = bb.DateRangeID AND g.DateID = bb.DateKey
),
agg_mig_m2m_clean AS (
  SELECT COUNT(DISTINCT g.CID) AS cids
  FROM ext g
  JOIN dwh_daily_process.migration_tables.fact_snapshotcustomer fsc
    ON g.ParentCID = fsc.RealCID AND fsc.AccountTypeID = 9
  JOIN dwh_daily_process.migration_tables.V_M2M_Date_DateRange bb
    ON fsc.DateRangeID = bb.DateRangeID AND g.DateID = bb.DateKey
  WHERE LENGTH(CAST(bb.DateRangeID AS STRING)) = 12
)
SELECT
  (SELECT cids FROM agg_gold_m2m) AS gold_m2m_cids,
  (SELECT cids FROM agg_mig_m2m) AS mig_m2m_cids,
  (SELECT cids FROM agg_mig_m2m_clean) AS mig_m2m_clean_cids,
  (SELECT COUNT(*) FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_m2m_date_daterange WHERE DateKey = 20260622) AS gold_m2m_keys,
  (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.V_M2M_Date_DateRange WHERE DateKey = 20260622) AS mig_m2m_keys
