WITH m AS (SELECT DISTINCT CID FROM dwh_daily_process.migration_tables.Fact_Guru_Copiers WHERE DateID=20260621),
g AS (SELECT DISTINCT CID FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers WHERE DateID=20260621)
SELECT
  (SELECT COUNT(*) FROM (SELECT CID FROM m LEFT ANTI JOIN g USING (CID))) AS in_mig_not_gold,
  (SELECT COUNT(*) FROM (SELECT CID FROM g LEFT ANTI JOIN m USING (CID))) AS in_gold_not_mig,
  (SELECT COUNT(*) FROM (SELECT CID FROM m JOIN g USING (CID))) AS in_both
