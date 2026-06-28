BEGIN
  CALL dwh_daily_process.migration_tables.sp_dim_mirror_dl_to_synapse(V_dt);
END