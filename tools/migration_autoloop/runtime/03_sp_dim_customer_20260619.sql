-- Task 3: SP_Dim_Customer
-- ADF source: DWH ETLs.json → Generic Exec SP (depends on DL_To_Synapse)
-- Target: dwh_daily_process.migration_tables.dim_customer
-- Actions: Detect new/changed CIDs → MERGE core → UPDATE Avatar, FTD, 
--          Screening, SalesForce, Docs, 2FA, ApexID, Phone, Tangany, DLT, 
--          StocksLending, UserName_Lower
CALL dwh_daily_process.migration_tables.sp_dim_customer();
