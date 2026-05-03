# Review Needed: eMoney_Tribe.SettlementsTransactions-333243

## Summary

All 9 columns are Tier 3 — grounded in DDL structure and SP code but no upstream wiki exists. The `_no_upstream_found.txt` marker is present, confirming this is an external Tribe Payments API ingestion table with no documented production source.

## Items for Human Review

### 1. Legacy Partition Columns (etr_y, etr_ym, etr_ymd)

- **Issue**: These three varchar(max) columns are 99.8% NULL (only 6,065 of 2,946,011 rows populated). They appear to be legacy ETL partition columns that were never fully adopted.
- **Question**: Can these columns be deprecated or dropped? They are not referenced by any SP or view in the codebase.
- **Impact**: Low — no downstream consumers identified.

### 2. Created vs @Created Duplication

- **Issue**: The `Created` column appears to be a copy of `@Created` but is NULL for ~26% of rows (770,930 records, all pre-2024 loads). The SP reads `@Created` from the child table, not this header table's `Created` column.
- **Question**: Is `Created` intended to replace `@Created` long-term? Should historical rows be backfilled?
- **Impact**: Medium — analysts could be confused by the two similarly-named columns with different NULL profiles.

### 3. Production Source Documentation

- **Issue**: This table ingests data from the Tribe Payments API (external card issuer). No upstream wiki or production schema documentation exists.
- **Question**: Is there internal documentation (Confluence, Freshservice, or Tribe API docs) that describes the XML schema and field definitions for settlement transaction exports?
- **Reference**: Freshservice Change #20353 (linked in SP header) may contain migration context.

### 4. UC Migration Status

- **Issue**: Table is marked `_Not_Migrated` to Unity Catalog.
- **Question**: Is this table a candidate for UC migration, or will only the compiled `ETL_SettlementsTransactions` target be migrated?

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — |
| Tier 2 | 0 | — |
| Tier 3 | 9 | @Created, @Id, @FileName, etr_y, etr_ym, etr_ymd, SynapseUpdateDate, partition_date, Created |
| Tier 4 | 0 | — |
