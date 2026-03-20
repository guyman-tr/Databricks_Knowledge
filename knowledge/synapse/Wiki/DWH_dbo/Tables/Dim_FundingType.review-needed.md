# DWH_dbo.Dim_FundingType - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None. All columns resolved to Tier 2 (SP code) or Tier 3 (live data).

## Columns Needing Clarification

- **FundingTypeID=41 missing**: The sequence goes 40, 42, 43, 44. Was FundingTypeID=41 deleted? What was it? Is this a historical artifact or expected gap?
- **DWHFundingTypeID purpose**: Currently equals FundingTypeID for all rows. Was this column intended for surrogate key substitution (different from source ID) that was never implemented? Or does it serve a specific DWH mapping purpose?
- **StatusID=1 meaning**: All rows have StatusID=1 (hardcoded). Does StatusID mean "active"? Is there a deactivation mechanism (StatusID=0 or similar) for deprecated payment methods?
- **FundingTypeID=27 hardcoding risk**: SP_Fact_CustomerAction hardcodes FundingTypeID=27 for IsRedeem calculation. Is this a known tech debt? Should this be data-driven instead?
- **UpdateDate vs InsertDate**: Both are set to GETDATE() on each SP run (same value). What was the original intent of having two timestamp columns? InsertDate should logically be the first load time only.

## Structural Questions

- **FundingTypeID smallint nullable**: Why nullable for a primary key? Fact table joins handle this with ISNULL(FundingTypeID, 0). Is there a case where a fact record genuinely has NULL FundingTypeID (no payment method)?
- **Name not renamed**: Unlike most DWH Dim_ tables where Name is renamed to XxxName (e.g., FundingTypeName), this column stays as `Name`. Was this intentional or an oversight?
- **No Dim_Status**: StatusID=1 is hardcoded but there is no `Dim_Status` table in DWH to decode it. Is StatusID used anywhere in queries, or is it vestigial?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
