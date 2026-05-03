# BI_DB_dbo.BI_DB_US_Stocks — Review Needed

## 1. Production Source Unknown

- **Issue**: No writer SP, no generic pipeline mapping, and no OpsDB entry found for this table. The data appears to have been loaded manually or via an ad-hoc script in 2019.
- **Action needed**: Confirm whether this table is still actively used or should be deprecated. SP_Daily_Dividends still references it, but the data has not been refreshed since 2019-11-24. New instruments added after that date are missing.
- **Risk**: The Is_US_Stock flag in BI_DB_Daily_Dividends may be inaccurate for instruments added after November 2019.

## 2. Duplicate InstrumentIDs

- **Issue**: InstrumentIDs 5945, 5946, 5947, and 5948 each appear twice. Five ticker names (SPHD/USD, SDY/USD, DVY/USD, VIG/USD, SPXU/USD) also have duplicate entries.
- **Action needed**: Determine if these duplicates are intentional or data quality issues. LEFT JOINs in SP_Daily_Dividends may produce row multiplication.

## 3. All Columns Tier 3

- **Issue**: All 3 columns are Tier 3 (grounded in DDL and live data only). No upstream wiki or writer SP exists to provide authoritative descriptions.
- **Action needed**: If the original data source is identified, upgrade column descriptions to Tier 1 or Tier 2.

## 4. Migration Artifacts

- **Issue**: `BI_DB_Migration.BI_DB_US_Stocks` and `BI_DB_Migration.JUNK_BI_DB_US_Stocks` exist in the SSDT repo, suggesting this table was migrated from a legacy system. The migration table uses `varchar(50)` for UpdateDate (vs. `datetime` in the current table).
- **Action needed**: Confirm migration artifacts can be cleaned up.

## 5. Dormancy Assessment

- **Issue**: Table has not been updated since 2019-11-24. It is not registered in OpsDB or the generic pipeline.
- **Action needed**: Evaluate whether this table should be marked as deprecated or archived. If SP_Daily_Dividends still runs daily, it uses stale US stock classification data.

---

*Generated: 2026-04-30*
