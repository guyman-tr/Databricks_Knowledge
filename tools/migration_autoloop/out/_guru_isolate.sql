SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT g.CID) AS cids,
  SUM(CAST(COALESCE(g.Cash,0) AS DECIMAL(38,4))) AS s_cash,
  SUM(CAST(COALESCE(g.Investment,0) AS DECIMAL(38,4))) AS s_inv,
  SUM(CAST(COALESCE(g.PnL,0) AS DECIMAL(38,4))) AS s_pnl
FROM (
  SELECT g.CID, g.DateID,
    SUM(COALESCE(g.Cash,0)) AS Cash,
    SUM(COALESCE(g.Investment,0)) AS Investment,
    SUM(COALESCE(g.PnL,0)) AS PnL
  FROM dwh_daily_process.migration_tables.Ext_FGC_Guru_Copiers g
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer fsc
    ON g.ParentCID = fsc.RealCID AND fsc.AccountTypeID = 9
  JOIN dwh_daily_process.migration_tables.V_M2M_Date_DateRange bb
    ON fsc.DateRangeID = bb.DateRangeID AND g.DateID = bb.DateKey
  GROUP BY g.CID, g.DateID
) g
