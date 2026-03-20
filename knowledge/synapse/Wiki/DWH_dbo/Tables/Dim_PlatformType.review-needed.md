# DWH_dbo.Dim_PlatformType - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| ProductID 99 vs 0 | Both represent "No Platform" with identical data. Is ProductID 99 a legacy alias, or does it signify something different (e.g., different system/region)? |
| InDevelopment IDs 4,5,7 | Were IDs 4 (Trader MobileWeb), 5 (OpenBook Android), 7 (OpenBook iOS) ever released? Or permanently deprecated? Relevant for any historical reporting that might filter InDevelopment = False. |
| CanOpenMirror vs CanCopyTrade | These appear to be different features (opening a mirror vs being a copy trader). Can you confirm the business distinction? |

## Structural Questions

| Question | Context |
|----------|---------|
| Platform detection deprecation | SP_Fact_CustomerAction has extensive commented-out platform detection logic (user-agent based, ClientType based). When was this deprecated and why? Is PlatformTypeID still useful for any live reporting? |
| Is this table expected to grow? | Are new platform types added as new products launch (e.g., options trading, US stocks app)? Or is this dimension permanently frozen? |
| ProductID vs PlatformTypeID naming | The DWH DDL uses `ProductID` as the PK column name, but Fact_CustomerAction references it as `PlatformTypeID`. This asymmetry may confuse analysts doing JOINs. |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|-----------------------------|--------------|----------------|
