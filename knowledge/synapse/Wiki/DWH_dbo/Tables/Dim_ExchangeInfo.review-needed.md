# DWH_dbo.Dim_ExchangeInfo - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None. All columns resolved to Tier 2 (SP code).

## Columns Needing Clarification

- **Orphaned dimension**: ExchangeID is commented out in SP_Fact_CustomerUnrealized_PnL. Was this intentionally removed? Is there a plan to re-enable it or is Dim_ExchangeInfo being phased out?
- **FRA (ID=6)**: Does FRA refer to Frankfurt Stock Exchange (XETRA)? The abbreviation is ambiguous.
- **TYO (ID=13)**: Likely Tokyo Stock Exchange but not confirmed from available data.
- **No upstream wiki**: etoro.Dictionary.ExchangeInfo has no upstream wiki in DB_Schema. If documentation exists elsewhere, column descriptions could be upgraded to Tier 1.

## Structural Questions

- Why are broad market categories (FX=1, Commodity=2, CFD=3) mixed with specific named exchanges (Nasdaq=4, NYSE=5) in the same dimension? Are these treated identically in business logic?
- The table has 51 rows. Are all 51 exchange IDs actively used, or are some legacy/inactive exchanges?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
