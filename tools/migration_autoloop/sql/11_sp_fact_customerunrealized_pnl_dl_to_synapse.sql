CALL dwh_daily_process.migration_tables.sp_fact_customerunrealized_pnl_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
);

