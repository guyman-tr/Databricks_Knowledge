SELECT COUNT(DISTINCT g.ParentCID) AS qualifying_parents
FROM dwh_daily_process.migration_tables.Ext_FGC_Guru_Copiers g
JOIN dwh_daily_process.migration_tables.fact_snapshotcustomer fsc
  ON g.ParentCID = fsc.RealCID AND fsc.AccountTypeID = 9
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_m2m_date_daterange bb
  ON fsc.DateRangeID = bb.DateRangeID AND g.DateID = bb.DateKey
WHERE g.DateID = 20260622
