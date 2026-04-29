# Review Needed: BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH

## 1. Schema Drift Between SSDT DDL and Runtime

- **Issue**: The SSDT DDL for this table declares 169 columns and `CLUSTERED COLUMNSTORE INDEX`, but the runtime SP (`SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE`) creates the table via `SELECT TOP 0 * FROM BI_DB_CID_DailyPanel_FullData` with `CLUSTERED INDEX (DateID ASC)`. The runtime version inherits whatever columns the parent currently has (183 as of April 2026).
- **Impact**: The SSDT DDL is stale — it lacks the 14 columns added to the parent table in 2024–2025 (V3_CompleteDate, EOD_LSD, ActiveOpen_Manual, ActiveOpen_Mirror, ActiveOpen_AirDrop, ActiveOpen_IncludeCopy, Revenue_IslamicFees, Revenue_TicketFees, Revenue_ConversionFees, Revenue_TicketFeeByPercent, Transactional_Revenue_Total, ACC_Transactional_Revenue_Total, CashoutsAdjusted, EOD_LSD). The runtime table will have all 183 columns.
- **Action**: Consider updating the SSDT DDL to match the parent table's current schema, or note that this DDL is intentionally behind because the SP re-creates the table dynamically.

## 2. Table Purpose

- **Confirm**: This table is exclusively used for partition switching during historical data loads. It should never contain data at rest and should never be queried for analytics. If it is found with rows, a switch operation either failed or is in progress.

## 3. No Tier 3 or Tier 4 Columns

- All 169 columns are direct schema-identical passthroughs from `BI_DB_CID_DailyPanel_FullData` via metadata-only partition switching. No columns required inference or lacked traceable sources.
