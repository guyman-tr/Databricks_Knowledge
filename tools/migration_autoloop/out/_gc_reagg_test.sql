WITH agg_mig_fsc AS (
  SELECT g.CID, g.DateID
  FROM dwh_daily_process.migration_tables.Ext_FGC_Guru_Copiers g
  JOIN dwh_daily_process.migration_tables.fact_snapshotcustomer fsc
    ON g.ParentCID = fsc.RealCID AND fsc.AccountTypeID = 9
  JOIN dwh_daily_process.migration_tables.V_M2M_Date_DateRange bb
    ON fsc.DateRangeID = bb.DateRangeID AND g.DateID = bb.DateKey
  WHERE g.DateID = 20260622
  GROUP BY g.CID, g.DateID
),
agg_gold_fsc AS (
  SELECT g.CID, g.DateID
  FROM dwh_daily_process.migration_tables.Ext_FGC_Guru_Copiers g
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer fsc
    ON g.ParentCID = fsc.RealCID AND fsc.AccountTypeID = 9
  JOIN dwh_daily_process.migration_tables.V_M2M_Date_DateRange bb
    ON fsc.DateRangeID = bb.DateRangeID AND g.DateID = bb.DateKey
  WHERE g.DateID = 20260622
  GROUP BY g.CID, g.DateID
)
SELECT
  (SELECT COUNT(*) FROM agg_mig_fsc) AS mig_fsc_agg_cids,
  (SELECT COUNT(*) FROM agg_gold_fsc) AS gold_fsc_agg_cids,
  (SELECT COUNT(*) FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers WHERE DateID = 20260622) AS gold_fact_cids
