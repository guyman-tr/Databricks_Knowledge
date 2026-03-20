# DWH_dbo.Dim_RiskClassification - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None - all columns are Tier 1 or Tier 2.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| RiskClassificationID ordering | ID=0 is "High" (highest active risk), ID=2 is "Low". The IDs are not ordered by severity. Was there a historic reason for this ordering? Or were new levels added later (Medium High=4, Medium Low=5)? |
| Unacceptable (ID=3) usage | RiskScore=200 is double the next-highest (High=100). What specific customer scenario triggers "Unacceptable"? Is this used for regulatory blacklists, PEP matches, or specific compliance flags? |

## Structural Questions

- **No DWH views reference this table**: Dim_RiskClassification has no DWH_dbo views joining it (unlike Dim_Regulation which is in V_Dim_Customer). Should it be added to a customer view?
- **RiskClassificationID nullable in DDL**: Per the REPLICATE pattern in Synapse, the PK column is nullable. Is there any row with NULL RiskClassificationID?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
