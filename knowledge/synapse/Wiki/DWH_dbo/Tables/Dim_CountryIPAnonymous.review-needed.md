# DWH_dbo.Dim_CountryIPAnonymous - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 [UNVERIFIED] columns in this document.

## Columns Needing Clarification

| Column / Topic | Question |
|----------------|----------|
| Fact_CustomerAction relationship | Does SP_Fact_CustomerAction explicitly JOIN Dim_CountryIPAnonymous to flag anonymous IPs in Fact_CustomerAction? Please confirm the ProxyType column exists in Fact_CustomerAction. |
| CountryCode 'NA' ambiguity | The SP uses `ISNULL(country_code,'NA')` to handle Namibia. Are there other cases where country_code is genuinely NULL (i.e., IP ranges with no assigned country)? If so, these would be incorrectly assigned to Namibia. |
| DCH classification | DCH (Data Center/Hosting) has Low anonymity per the proxy type taxonomy. Are all DCH ranges considered suspicious in the fraud model, or only a subset (e.g., specific cloud providers)? |
| CountryID NULL rows | When CountryCode does not match any Dim_Country.Abbreviation, CountryID remains NULL. How many rows have NULL CountryID? Is this tracked? |

## Structural Questions

| Question |
|----------|
| DWH_staging.IP2Location - is this loaded from a Generic Pipeline parquet file, or from a direct database integration? IP2Location is an external commercial provider. How is the license managed for refresh? |
| REPLICATE at 4.8M rows is borderline for Synapse memory. Should this be HASH DISTRIBUTED on IPFrom? |
| There is no primary key on this table. Can the same IP range appear multiple times with different ProxyTypes (overlapping ranges)? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
