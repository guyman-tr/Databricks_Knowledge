BEGIN
  CALL dwh_daily_process.migration_tables.sp_fact_deposit_state(V_dt);
END