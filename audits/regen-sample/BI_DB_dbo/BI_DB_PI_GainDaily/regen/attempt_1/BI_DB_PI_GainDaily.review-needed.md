# Review Needed: BI_DB_dbo.BI_DB_PI_GainDaily

## 1. Data Freshness Concern

The table has not been refreshed since **2024-04-14**. The parent SP `SP_PI_Dashboard_COPYDATA_RuningSideBySide` appears to have stopped running at this date. The parent dashboard table `BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide` also shows the same cutoff date.

**Action needed**: Confirm whether the PI Dashboard pipeline was intentionally decommissioned or if this is an operational issue.

## 2. Tier Classification Notes

All 9 gain columns are **direct passthroughs** from `DWH_GainDaily` with no transformation. However, since `DWH_GainDaily` itself is an ETL-computed table (pivoted from the TradeGain Ranking service with no upstream production wiki), these columns inherit Tier 2 from the upstream table rather than Tier 1.

The `CID` column is Tier 1 (passthrough from Customer.CustomerStatic via DWH_GainDaily).

## 3. Population Drift

The table does not purge historical rows for customers who lose PI status. If a PI is demoted (e.g., GuruStatusID changed to 7=Removed), their historical gain rows remain in the table indefinitely, but no new rows are added. This means the table's historical row count overstates the active PI population at any given point in time.

## 4. Not Migrated to Unity Catalog

This table is marked `_Not_Migrated` in the UC target. No UC copy exists.
