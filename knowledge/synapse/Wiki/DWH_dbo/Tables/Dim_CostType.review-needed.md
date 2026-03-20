# DWH_dbo.Dim_CostType - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 [UNVERIFIED] columns in this document.

## Columns Needing Clarification

| Column / Topic | Question |
|----------------|----------|
| CostTypeId (Relationship) | Is Dim_CostType.CostTypeId referenced by Fact_History_Cost? No SP grep match found. Please confirm the downstream consumers. |
| CurrencyMarkup (ID=2) | Is CurrencyMarkup always a separate row from Markup (ID=1) in Fact_History_Cost, or can a single trade row have both? |
| Tax (ID=4) | Are there tax types other than SDRT planned? The current 7-row Dim_CostSubtype only shows SDRT as a tax subtype. |

## Structural Questions

| Question |
|----------|
| Why ROUND_ROBIN for a 4-row table? Should this be REPLICATE for broadcast joins? |
| HistoryCosts is not in the Generic Pipeline. What is the actual mechanism that loads DWH_staging.HistoryCosts_Dictionary_CostType - ADF pipeline, SQL linked server, or something else? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
