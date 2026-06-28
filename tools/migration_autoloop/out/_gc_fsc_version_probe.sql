WITH ext AS (
  SELECT * FROM dwh_daily_process.migration_tables.Ext_FGC_Guru_Copiers WHERE DateID = 20260622
),
v91 AS (
  SELECT COUNT(DISTINCT g.CID) AS cids
  FROM ext g
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer VERSION AS OF 91 fsc
    ON g.ParentCID = fsc.RealCID AND fsc.AccountTypeID = 9
  JOIN dwh_daily_process.migration_tables.V_M2M_Date_DateRange bb
    ON fsc.DateRangeID = bb.DateRangeID AND g.DateID = bb.DateKey
),
v92 AS (
  SELECT COUNT(DISTINCT g.CID) AS cids
  FROM ext g
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer VERSION AS OF 92 fsc
    ON g.ParentCID = fsc.RealCID AND fsc.AccountTypeID = 9
  JOIN dwh_daily_process.migration_tables.V_M2M_Date_DateRange bb
    ON fsc.DateRangeID = bb.DateRangeID AND g.DateID = bb.DateKey
),
v93 AS (
  SELECT COUNT(DISTINCT g.CID) AS cids
  FROM ext g
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer VERSION AS OF 93 fsc
    ON g.ParentCID = fsc.RealCID AND fsc.AccountTypeID = 9
  JOIN dwh_daily_process.migration_tables.V_M2M_Date_DateRange bb
    ON fsc.DateRangeID = bb.DateRangeID AND g.DateID = bb.DateKey
)
SELECT v91.cids AS v91_cids, v92.cids AS v92_cids, v93.cids AS v93_cids,
  (SELECT COUNT(DISTINCT CID) FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers WHERE DateID = 20260622) AS gold_fact_cids
FROM v91 CROSS JOIN v92 CROSS JOIN v93
