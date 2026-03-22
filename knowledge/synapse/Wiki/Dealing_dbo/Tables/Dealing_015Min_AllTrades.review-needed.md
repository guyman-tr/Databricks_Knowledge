# Dealing_dbo.Dealing_015Min_AllTrades — Review Needed

> Items flagged for domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|
| | | | | | |

## Tier 4 (UNVERIFIED) Columns

- **UpdateDate** — Assumed ETL load timestamp; confirm if it reflects insert-only, upsert, or external loader clock.

## Columns Needing Clarification

- **`Unit` vs `quantity`** — Are they interchangeable, or does **`Unit`** represent lots/contracts?
- **`Value` vs `Funds`** — Currency, fee inclusion, and exact formula from the feed.
- **`Source` vs `source_name`** — Intended distinction between the two feed-key columns.

## Structural Questions

- **Which LP or exchange** populated this table (APEX, IB, other)? Confirm from operations or ADF/SSIS catalog.
- **Why the pipeline stopped in April 2024** — superseded by another table/feed or decommissioned product?
- **`char(50)` columns** — Confirm fixed-width is intentional from vendor layout (vs migrating to `varchar`).
- **Float financial columns** — Whether decimal types were rejected for feed compatibility or should be revised in any revival design.
