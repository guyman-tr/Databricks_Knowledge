# DWH_dbo.Dim_MifidCategorization -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all columns traced to SP code or live data.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| MifidCategorizationID=0 (None) | For EU-regulated customers, does MifidCategorizationID=0 represent a data quality gap (customer should be classified but isn't), or is it a valid state for non-EU customers only? Knowing the expected distribution would help analysts flag anomalies. |
| MifidCategorizationID=4 vs 5 | What is the practical difference between 'Retail Pending' (4) and 'Pending' (5)? Are these both transitional states, and if so, do they have different SLAs or triggers for resolution? |

## Structural Questions

| Question |
|----------|
| Only 6 rows in this table. Are new MiFID classification IDs expected to be added (e.g., if eToro expands into new regulatory regimes with different tiers), or is this set static? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On | New Tier 1-3 | Change Summary |
|--------|-------------------|--------------|--------------|----------------|
