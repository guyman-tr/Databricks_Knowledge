# Review Needed — eMoney_dbo.eMoney_AM_Target

## Tier 4 Items (Best-Guess / Needs Expert Confirmation)

None. All columns traced to SP code directly.

## Flags / Reviewer Questions

1. **SP Suspension**: `SP_eMoney_AM_Target` is commented out (SP 13) in `SP_eMoney_Execute_Group_One`. Is this table being deprecated? Max date is 2026-04-11 (~10 days stale). Reviewer should confirm whether this table is still operational or being replaced.

2. **Contact Dates Disabled**: `Attemp_Last_Date` and `Contacted_Last_Date` are always `1900-01-01`. The original code sourced these from `BI_DB.dbo.BI_DB_UsageTracking_SF`. Is this feature planned to be re-enabled?

3. **Hardcoded Target Window**: The `*_Targets` columns always reflect 2023-07-01 to 2023-10-01. Was this a one-time target window? Are new target periods defined elsewhere?

4. **Euro_Non_Euro Country IDs**: The CASE uses hardcoded CountryIDs (154=Poland, 196=Sweden, 72=Denmark, 57=Czech Republic, 95=Hungary — inferred). Reviewer should confirm exact country mapping. The SP does not document what these country IDs represent.

5. **eToro Money vs Other funding distinction**: FundingTypeID=33 is used as the eToro Money distinguishing value. Reviewer should confirm this is still the correct FundingTypeID for eTM.

## Data Quality Observations

- Large table (385M rows) with no indexes or partitioning — all date queries are full table scans
- `Attemp_Last_Date` / `Contacted_Last_Date` are date type but store '1900-01-01' sentinel (not NULL)
- `Report_Date` is nullable (date type YES) despite being the key grouping column
