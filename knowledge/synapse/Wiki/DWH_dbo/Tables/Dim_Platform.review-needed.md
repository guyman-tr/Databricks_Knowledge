# DWH_dbo.Dim_Platform -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all 3 columns have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

- **PlatformID consumers**: Only SP_Dictionaries_DL_To_Synapse was found referencing this table. Are there Fact tables (e.g., Fact_CustomerAction) that join on PlatformID? Or is Dim_Platform effectively orphaned in the current DWH? Clarifying this would improve the "Referenced By" section.
- **Distinction from Dim_PlatformType**: Dim_PlatformType (13 rows, batch 5) is a legacy migration table. Dim_Platform (4 rows) is the active production dictionary. Confirm if both are used in parallel or if one supersedes the other.

## Structural Questions

- **Column rename Id -> PlatformID**: Confirmed from SP code. Is this rename intentional policy (standardize *ID suffix) or an accident? Documenting the policy would clarify whether other `Id` columns in staging are similarly renamed.
- **ETL freshness**: UpdateDate 2026-03-11 (8 days stale). See schema-wide ETL disruption note from batch_2_knowledge.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
