# CardsSnapshots-890718 — Review Needed

## 1. Tier 3 Coverage

All 9 columns are Tier 3. No upstream wiki exists (`_no_upstream_found.txt` confirmed). Column descriptions are grounded in DDL structure, data sampling, and SP code analysis (`SP_eMoney_Reconciliation_ETLs`).

## 2. Items for Human Review

- **ETR partition columns (`etr_y`, `etr_ym`, `etr_ymd`)**: ~99.5% empty. Confirm whether these are intentionally unpopulated for this table or represent a data pipeline issue. Consider whether these columns should be dropped.
- **`@Created` vs `Created` redundancy**: Both carry near-identical timestamps. Confirm whether `Created` is a deliberate copy or an artifact. The SP uses `@Created` for incremental filtering.
- **`@FileName` now NULL in downstream**: As of the 2025-12-21 SP change, `@FileName` is replaced with NULL in the final INSERT into `ETL_CardSnapshot`. The column still has data in this source table but is no longer propagated. Confirm whether this column retains value for data lake traceability.
- **No UC migration target**: Table is marked `_Not_Migrated`. Confirm whether this raw Tribe landing table is intended to remain Synapse-only or has a planned UC migration path.
- **Production source unknown**: This is a Tribe raw data landing table loaded via generic pipeline from data lake XML files. No upstream production database wiki exists. The Freshservice ticket (#20353) may contain additional context about the original data source.

## 3. SP Change History

| Date | Author | Change |
|---|---|---|
| 2024-08-18 | Eitan Lipovetsky | Insert into temp table AccountsSnapshots-509416 for performance |
| 2024-08-26 | Eitan Lipovetsky | Insert into temp table CardsSnapshots_CardSnapshot-140457 for performance |
| 2025-03-02 | Eitan Lipovetsky | Insert into temp table CardsSnapshots_140457 for performance |
| 2025-12-21 | Inessa | Add DISTINCT and remove filename to avoid duplicates handling; export banking payments for UK to subledger |
