WITH ext AS (SELECT * FROM dwh_daily_process.migration_tables.Ext_FGC_Guru_Copiers),
v AS (SELECT explode(array(88,89,90,91,92,93)) AS ver)
SELECT 93 AS ver, COUNT(DISTINCT g.CID) AS cids FROM ext g
  JOIN (SELECT RealCID, AccountTypeID, DateRangeID FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer VERSION AS OF 93) fsc ON g.ParentCID=fsc.RealCID AND fsc.AccountTypeID=9
  JOIN dwh_daily_process.migration_tables.V_M2M_Date_DateRange bb ON fsc.DateRangeID=bb.DateRangeID AND g.DateID=bb.DateKey
UNION ALL
SELECT 92, COUNT(DISTINCT g.CID) FROM ext g
  JOIN (SELECT RealCID, AccountTypeID, DateRangeID FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer VERSION AS OF 92) fsc ON g.ParentCID=fsc.RealCID AND fsc.AccountTypeID=9
  JOIN dwh_daily_process.migration_tables.V_M2M_Date_DateRange bb ON fsc.DateRangeID=bb.DateRangeID AND g.DateID=bb.DateKey
UNION ALL
SELECT 91, COUNT(DISTINCT g.CID) FROM ext g
  JOIN (SELECT RealCID, AccountTypeID, DateRangeID FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer VERSION AS OF 91) fsc ON g.ParentCID=fsc.RealCID AND fsc.AccountTypeID=9
  JOIN dwh_daily_process.migration_tables.V_M2M_Date_DateRange bb ON fsc.DateRangeID=bb.DateRangeID AND g.DateID=bb.DateKey
UNION ALL
SELECT 90, COUNT(DISTINCT g.CID) FROM ext g
  JOIN (SELECT RealCID, AccountTypeID, DateRangeID FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer VERSION AS OF 90) fsc ON g.ParentCID=fsc.RealCID AND fsc.AccountTypeID=9
  JOIN dwh_daily_process.migration_tables.V_M2M_Date_DateRange bb ON fsc.DateRangeID=bb.DateRangeID AND g.DateID=bb.DateKey
UNION ALL
SELECT 89, COUNT(DISTINCT g.CID) FROM ext g
  JOIN (SELECT RealCID, AccountTypeID, DateRangeID FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer VERSION AS OF 89) fsc ON g.ParentCID=fsc.RealCID AND fsc.AccountTypeID=9
  JOIN dwh_daily_process.migration_tables.V_M2M_Date_DateRange bb ON fsc.DateRangeID=bb.DateRangeID AND g.DateID=bb.DateKey
ORDER BY ver DESC
