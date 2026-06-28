-- Task 2: SP_Fact_CustomerAction_DL_To_Synapse
-- ADF source: Fact_CustomerAction_ETL.json → EXEC SP_Fact_CustomerAction_DL_To_Synapse
-- Target: dwh_daily_process.migration_tables.fact_customeraction
CALL dwh_daily_process.migration_tables.sp_fact_customeraction_dl_to_synapse(CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP));
