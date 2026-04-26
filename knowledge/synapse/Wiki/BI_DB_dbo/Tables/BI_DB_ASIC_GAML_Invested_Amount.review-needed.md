# Review Needed: BI_DB_dbo.BI_DB_ASIC_GAML_Invested_Amount

Generated: 2026-04-23 | Batch: 54 | Pipeline: build-wiki-bidb-batch

---

## 🔴 HIGH PRIORITY — SP Bug Requiring Code Fix

### @Date30INT computed from wrong variable

**File**: `BI_DB_dbo/Stored Procedures/BI_DB_dbo.SP_ASIC_GAML_Invested_Amount.sql`

**Current code (line ~18)**:
```sql
DECLARE @Date30INT INT = CONVERT(VARCHAR, @Date, 112)
```

**Should be**:
```sql
DECLARE @Date30INT INT = CONVERT(VARCHAR, @Date30, 112)
```

**Impact**: LogginInd and TradingInd columns in BI_DB_ASIC_GAML_Invested_Amount capture only same-day activity instead of the intended 30-day lookback. Any ASIC/GAML reporting or AML dormancy classification that relies on these flags is receiving incorrect data. Bug has been present since SP creation (2022-10-25).

**Action required**: SP owner (Artyom Bogomolsky) or current maintainer should apply the one-character fix and confirm downstream report consumers are aware of historical data quality issue.

---

## 🟡 MEDIUM — UC Migration Status

**UC Target**: `_Not_Migrated`

This table has no Unity Catalog migration target defined. If ASIC/GAML regulatory reporting is being moved to Databricks, this table should be included in scope. The `_Not_Migrated` status means no ALTER script was generated — raise with the migration team if needed.

---

## 🟡 MEDIUM — AssetType vs InstrumentType Redundancy

Columns 13 (InstrumentType) and 14 (AssetType) carry semantically equivalent values ('Stocks'/'ETF') derived from the same source (InstrumentTypeID). The SP applies a separate CASE expression for AssetType rather than reusing InstrumentType. This redundancy is intentional for ASIC column naming conventions but may confuse downstream analysts. Consider adding a note to any consuming reports.

---

## ℹ️ INFO — Single-Date Snapshot Only

This table always holds exactly one date (today's ETL run date). No historical data is retained. If historical ASIC invested-amount analysis is needed, it must come from a separate historical table or from a lake-level archive. Current consumers should not join this table expecting multi-date data.
