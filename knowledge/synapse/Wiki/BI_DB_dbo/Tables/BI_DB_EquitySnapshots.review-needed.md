# Review Needed: BI_DB_dbo.BI_DB_EquitySnapshots

Generated: 2026-04-22 | Reviewer: —

## Tier 4 Items (Unverified — Human Review Required)

None — all columns are Tier 1 or Tier 2.

## Questions for SME

1. **Size trajectory**: At 13.37B rows, this table grows by ~1–1.5M rows daily. Is there a retention/archival policy? The SP code comment says "2,298,557,131 rows" (written ~2019-2021), suggesting growth from 2.3B to 13.37B — is historical data ever purged?

2. **UpdateDate NULL for early rows**: Rows from 2013–2015 appear to have NULL UpdateDate (sample shows CID=701 from 20130101 with NULL UpdateDate). Was UpdateDate added retroactively, or were these rows migrated from a prior system?

3. **Equity threshold >= $50**: The risk model uses `RealizedEquity + PositionPnL >= 50` to filter eligible CIDs. This threshold is hardcoded since 2017 — has it ever been reviewed or should it be configurable?

4. **NOLOCK hints**: The SP uses `WITH (NOLOCK)` on Fact_SnapshotEquity, Dim_Range, BI_DB_EquitySnapshots reads. In a production Synapse environment (snapshot isolation), are these hints intentional or legacy?

5. **Month-end ActivitySegment update**: The SP runs a monthly re-classification (Trader/Crypto/Investor) at month-end using commission and equity data. This updates `BI_DB_User_Segment_Snapshot` but does NOT add rows to `BI_DB_EquitySnapshots` — confirm this is correct.

## Corrections Log

No corrections applied.

## Pipeline Flags

- **UC Target**: _Not_Migrated — no Unity Catalog migration planned as of 2026-04-22.
- **Row count**: 13.37 billion — largest table documented in BI_DB_dbo to date.
- **Dependency note**: OpsDB shows BI_DB_DailyCommisionReport as a dependency of SP_User_Segment_Snapshot — used in month-end ActivitySegment calculation (#comm temp table, not in daily equity INSERT).
