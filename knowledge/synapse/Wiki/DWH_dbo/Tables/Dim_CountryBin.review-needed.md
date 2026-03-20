# DWH_dbo.Dim_CountryBin - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 [UNVERIFIED] columns in this document.

## Columns Needing Clarification

| Column / Topic | Question |
|----------------|----------|
| BinCode uniqueness | Is BinCode unique in Dim_CountryBin, or can the same BIN appear with multiple CountryIDs? The production source uses CountryID+BinCode as a composite PK, but DWH only has CLUSTERED INDEX on BinCode (not unique). |
| 6-digit vs 8-digit BINs | How does deposit processing choose between 6-digit and 8-digit BIN matches when both exist? Does the application try 8-digit first and fall back to 6-digit? |
| ChallengeIndicator3DS (dropped) | The upstream source has ChallengeIndicator3DS which is not loaded to DWH. Is this intentional? Does any DWH analytics query need this field? |
| SupportsAFT / IsCFT (dropped) | SupportsAFT and IsCFT are not loaded to DWH. Are these needed for any DWH-based payment analytics? |
| CardTypeID=13 | Many rows show CardTypeID=13 in live data. What does 13 represent in Dim_CardType? Is this a "catch-all" unknown type? |
| REPLICATE on 16.3M rows | REPLICATE for a 16M row table is unusual - Synapse may silently downgrade to HASH distribution at runtime. Has this been verified as performing correctly? Should it be HASH DISTRIBUTED on BinCode? |

## Structural Questions

| Question |
|----------|
| The staging table has columns `ProductType` and `Category` alongside `CardSubType` and `CardCategory`. Are these overlapping/redundant columns or do they have distinct meanings? |
| How is the staging table `DWH_staging.etoro_Dictionary_CountryBin` populated - does it come from a Generic Pipeline parquet file that pre-merges CountryBin6 and CountryBin8, or a direct database load? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
