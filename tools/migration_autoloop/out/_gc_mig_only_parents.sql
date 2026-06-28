WITH mig_only AS (
  SELECT m.CID
  FROM dwh_daily_process.migration_tables.Fact_Guru_Copiers m
  LEFT ANTI JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers g
    ON m.CID = g.CID AND g.DateID = 20260622
  WHERE m.DateID = 20260622
)
SELECT COUNT(DISTINCT ext.ParentCID) AS distinct_parents
FROM mig_only mo
JOIN dwh_daily_process.migration_tables.Ext_FGC_Guru_Copiers ext ON ext.CID = mo.CID AND ext.DateID = 20260622
