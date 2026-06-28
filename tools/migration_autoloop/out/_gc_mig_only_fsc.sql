WITH mig_only AS (
  SELECT m.CID
  FROM dwh_daily_process.migration_tables.Fact_Guru_Copiers m
  LEFT ANTI JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers g
    ON m.CID = g.CID AND g.DateID = 20260622
  WHERE m.DateID = 20260622
)
SELECT COUNT(*) AS mig_only_cids,
  SUM(CASE WHEN fsc.RealCID IS NOT NULL THEN 1 ELSE 0 END) AS with_fsc_parent_match
FROM mig_only mo
JOIN dwh_daily_process.migration_tables.Ext_FGC_Guru_Copiers ext ON ext.CID = mo.CID
LEFT JOIN dwh_daily_process.migration_tables.fact_snapshotcustomer fsc
  ON ext.ParentCID = fsc.RealCID AND fsc.AccountTypeID = 9
