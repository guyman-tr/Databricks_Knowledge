-- Task 2: SP_Dim_Customer_DL_To_Synapse
-- ADF source: DWH ETLs.json → Generic Exec SP (depends on Channel_Affiliate)
-- Builds: All Ext_Dim_Customer_* staging tables from daily_snapshot sources
-- Param: V_dt = yesterday (matches ADF @pipeline().parameters.DailyDate)
CALL dwh_daily_process.migration_tables.sp_dim_customer_dl_to_synapse(
    CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
);

CALL dwh_daily_process.migration_tables.sp_dim_customer()