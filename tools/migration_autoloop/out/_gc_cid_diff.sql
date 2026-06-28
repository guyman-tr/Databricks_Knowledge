WITH g AS (
  SELECT CID FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers WHERE DateID = 20260622
),
m AS (
  SELECT CID FROM dwh_daily_process.migration_tables.Fact_Guru_Copiers WHERE DateID = 20260622
)
SELECT
  (SELECT COUNT(*) FROM g) AS gold_cids,
  (SELECT COUNT(*) FROM m) AS mig_cids,
  (SELECT COUNT(*) FROM m LEFT ANTI JOIN g USING (CID)) AS mig_only,
  (SELECT COUNT(*) FROM g LEFT ANTI JOIN m USING (CID)) AS gold_only
