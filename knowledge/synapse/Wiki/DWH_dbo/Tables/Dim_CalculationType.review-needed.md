# DWH_dbo.Dim_CalculationType -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 (UNVERIFIED) columns. CalculationTypeId and CalculationType are Tier 3 (name-inferred from live values). UpdateDate is Tier 2.

## Columns Needing Clarification

| Column | Issue |
|--------|-------|
| CalculationType | The value names are self-descriptive code-style strings (FixPerUnit, PipsPerUnit, etc.). Confirm: do these map to enum values in the HistoryCosts application code? Is PercentOfMarketDataMarkup the markup component of the spread, or a percentage of a separate markup fee structure? What cost attribution does FixPerLot represent? |

## Structural Questions

1. **ROUND_ROBIN distribution**: This 8-row table uses ROUND_ROBIN instead of REPLICATE. Every JOIN with this table incurs data movement in Synapse. Was this a default applied without considering table size? Should be changed to REPLICATE.
2. **No ID=0 placeholder**: Unlike most DWH Dim_ tables, there is no N/A placeholder row (ID=0). If HistoryCosts fact tables have NULL CalculationTypeId values, they cannot be LEFT JOINed to this dimension safely.
3. **nvarchar(max) vs varchar(50)**: Production is varchar(50); DWH promotes to nvarchar(max). This is wasteful for 8 short string values and may affect query performance.
4. **No upstream wiki for HistoryCosts**: The HistoryCosts database has no corresponding wiki in DB_Schema/HistoryCosts/Wiki/. The description above is based solely on live data value names (Tier 3 confidence). A HistoryCosts domain expert should confirm the precise semantics of each calculation method.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
