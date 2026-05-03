-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.V_EXW_C2F_E2E_4Export
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- V_EXW_C2F_E2E_4Export is the export-ready surface of the Crypto-to-Fiat (C2F) E2E reconciliation data. The suffix `_4Export` signals its purpose: the view exists specifically to bridge the internal DWH data model (which uses `uniqueidentifier` columns natively) to export consumers that require string-compatible identifiers. The two uniqueidentifier columns in EXW_C2F_E2E - `C2FCorrelationID` (the distributed tracing correlation GUID) and `SentWalletID` (the wallet GUID from WalletDB) - are cast to varchar(50) so that: - Power BI DirectQuery and Import mode can handle them without data type errors - Excel/ODBC exports produce human-readable GUID strings instead of binary blobs - Downstream file exports (CSV, Parquet) get consistent string representations For all analytical, operational, and reporting use cases, **this view and the base table EXW_C2F_E2E are functionally equivalent**. Use 

