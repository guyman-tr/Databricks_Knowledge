# Review Needed — BI_DB_dbo.BI_DB_FirstTimeRev10

**Generated**: 2026-04-23 | **Batch**: 70 | **Quality**: 8.3/10

## Tier 4 Items (Undetermined — Pending Review)

None. All columns resolved to Tier 1 or Tier 2.

## Questions for Domain Expert

1. **SP code inaccessible**: `SP_FirstTimeRev10` shows an empty definition in `sys.sql_modules` and has no SSDT file. All column descriptions are inferred from data evidence. Please confirm: (a) the exact selection logic (does it use the first closed position, or earliest qualifying date?), (b) whether it does a full reload or incremental append, and (c) what the source table is (Trade.PositionTbl directly, or via a DWH intermediate?).

2. **AggregatedCommission definition**: Is `AggregatedCommission` the gross spread/commission eToro earned on the position (platform revenue), or is it the customer's P&L? The name "commission" and the $10 floor suggest it is platform revenue, but please confirm.

3. **Historical coverage gap**: The earliest Date is 2017-06-01. Were customers who first crossed $10 before that date excluded, or was the table created in mid-2017 with no backfill? Are there known pre-2017 customers who should be in this table but are missing?

4. **Downstream consumers**: `BI_DB_MarketingMonthlyRawData` (via `SP_Marketing_Cube`) is the suspected downstream consumer, but this was inferred — no SP definition confirmed it. Please confirm what tables read from `BI_DB_FirstTimeRev10`.

5. **Update behavior**: Is this table strictly append-only (CID inserted once, never updated), or can a CID's row be corrected/replaced (e.g., if the qualifying position is later reversed)?

## Propagation Metadata

- `UpdateDate` is ETL metadata (SP_FirstTimeRev10 run timestamp) — confirmed Propagation tier. All rows for a given Date share the same UpdateDate (05:03:58 AM next morning).

## Corrections Log

*(Empty — no reviewer corrections yet)*
