# DWH_dbo.Dim_Instrument_Snapshot -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all 9 columns traced to SP code (Tier 2) or live data (Tier 3).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| SettlementTime | The SP converts Dim_Instrument.SettlementTime (time(7)) into DATETIME using the snapshot date. Is this intentional -- i.e., consumers are expected to compare SettlementTime directly against position open/close DATETIMEs? Or should consumers extract only the time component when using this column? |
| ProviderMarginPerLot | This is NULL for many futures instruments (no entry in FuturesInstrumentsInitialMarginByProviderMapping). Is this expected? Are those instruments traded on fixed margin or does NULL mean "provider margin not tracked for this instrument"? |

## Structural Questions

| Question |
|----------|
| The SP uses DELETE + INSERT pattern with DateID range check. If the same @dt is passed twice in one day, the old rows for @Yesterdayint are deleted and replaced. Is there any risk of double-run on the same date? Is there an ETL guard or idempotency check upstream? |
| The UC target (`uc_table`) is empty in the Generic Pipeline mapping. Is this table exported to Databricks and available for analysis? If not, does that need to be remediated? |
| The snapshot holds ALL instruments (IsFuture=0 included), which means 98.4% of rows carry NULL futures columns. Was this intentional (to allow "at-date" instrument count queries), or should the snapshot be filtered to IsFuture=1 only at insert time to reduce storage? |
| No DateID < 20241222 exists. Were futures configuration changes before 2024-12-22 ever backfilled? Is there a plan to backfill historical dates? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On | New Tier 1-3 | Change Summary |
|--------|-------------------|--------------|--------------|----------------|
