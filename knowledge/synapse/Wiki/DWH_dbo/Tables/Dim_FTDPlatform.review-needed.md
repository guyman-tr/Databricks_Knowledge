# DWH_dbo.Dim_FTDPlatform - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns - all 2 elements are Tier 3 (live data / sampling).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| FTDPlatformID / FTDPlatformName | Live data shows 4 rows (TradingPlatform, Options, eMoney, MoneyFarm). Batch context previously noted "Undefined/Web/IOS/Android" which is INCORRECT based on live sampling. The live values appear to be eToro sub-product types, not device platforms. Is this interpretation correct? |
| FTDPlatformName | Is 'MoneyFarm' the Moneyfarm UK ISA product (eToro's acquisition)? Confirming the business domain of each sub-platform would improve descriptions. |

## Structural Questions

| Question | Context |
|----------|---------|
| What writes to this table? | No ETL SP found that INSERTs into DWH_dbo.Dim_FTDPlatform. 4 rows appear manually loaded. Is there a one-time script or was this an ad-hoc INSERT? |
| Is this table expected to grow? | MoneyBusDB.Dictionary.AccountTypes may have more account types in production. Should a refresh SP be created, or is this permanently static at 4 rows? |
| Why no ID=0 placeholder? | Most DWH dimension tables have an ID=0 'N/A' row for fact JOINs. Dim_Customer.FTDPlatformID can be NULL (non-depositors). Should ID=0 be added? |
| Relationship to BI_DB_dbo.V_Dim_FTDPlatform | The BI_DB view implements the same mapping via CASE expression over the external table. Why does DWH have a separate static table? Is there a risk of the two diverging? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|-----------------------------|--------------|----------------|
