# DWH_dbo.Dim_FundType - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None. All columns resolved to Tier 2 (SP code) or Tier 3 (live data).

## Columns Needing Clarification

- **FundType=1 "TopTraders" meaning**: Is TopTraders a specific eToro product (e.g., a curated set of copy trader portfolios) or a generic label? Does it correspond to the eToro "Top Traders" feature in the app?
- **FundType=2 "Partners" scope**: Who are the "Partners"? Are these institutional partners, CopyPortfolio partners, or affiliate-managed funds?
- **Description vs FundTypeName**: The source uses `Description` while DWH uses `FundTypeName`. Is there ever a case where these diverge in value (e.g., if Description has a longer text)?

## Structural Questions

- **varchar(50) vs nvarchar**: FundTypeName is varchar(50) (non-Unicode). Unlike other dict tables that use nvarchar(max). Intentional given fund type names are ASCII? Consistent with source schema?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
