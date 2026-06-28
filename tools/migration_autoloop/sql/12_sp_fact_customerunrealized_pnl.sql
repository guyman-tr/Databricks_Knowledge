CALL dwh_daily_process.migration_tables.sp_fact_customerunrealized_pnl_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
);

