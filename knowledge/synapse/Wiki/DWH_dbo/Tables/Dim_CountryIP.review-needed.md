# DWH_dbo.Dim_CountryIP - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 [UNVERIFIED] columns in this document.

## Columns Needing Clarification

| Column / Topic | Question |
|----------------|----------|
| RegionID | RegionID is sub-national (below country level). What dimension table does this map to in DWH? Is there a DWH_dbo.Dim_Region table, or is this only meaningful in the production etoro system? |
| IP range overlaps | Can a single IP integer match multiple rows in Dim_CountryIP (overlapping ranges)? If so, which row should take precedence - shortest range, or most recent? Does the DWH or analytics queries handle this correctly? |
| REPLICATE at 6.8M rows | Is REPLICATE intentional at 6.8M rows? Synapse documentation suggests REPLICATE is optimal for tables <2M rows. Has this caused issues with memory or performance? |

## Structural Questions

| Question |
|----------|
| The IP lookup use case is mostly OLTP (real-time registration/login). How often is Dim_CountryIP used for analytical DWH queries vs being a pass-through reference for data enrichment? |
| Does the DWH include both IPv4 and IPv6 ranges, or only IPv4? (The bigint type supports IPv6 addresses in theory but the production wiki only describes IPv4.) |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
