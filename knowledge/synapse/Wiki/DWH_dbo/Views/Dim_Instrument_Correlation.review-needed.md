# DWH_dbo.Dim_Instrument_Correlation — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all elements derived from SP code analysis (Tier 2).

## Columns Needing Clarification

1. **Archive policy**: When are rows moved from the 20 active tables to `Dim_Instrument_Correlation_Archive`? No SP was found that performs this archival — is it manual or scheduled?
2. **Group count target**: The magic number `89` in `SP_Build_GroupsInstruments` — why 89? Is this related to the 20 partition tables × ~4.5 groups each, or some other constraint?
3. **Price source**: `Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted` — is this an external table pointing to a data lake Parquet file, or a Synapse synonym? The `Ext_` prefix suggests external but the table definition was not found.

## Structural Questions

1. **Partition table count**: Why exactly 20 tables? Is there a scaling plan if the instrument universe grows?
2. **Self-correlation rows**: Rows where `InstrumentID_a = InstrumentID_b` have correlation = 1.0. Are these consumed by any downstream logic, or are they unnecessary overhead?
3. **Daily vs. on-demand**: Is the correlation computation run daily as part of the main ETL schedule, or triggered on-demand before specific risk reports?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
