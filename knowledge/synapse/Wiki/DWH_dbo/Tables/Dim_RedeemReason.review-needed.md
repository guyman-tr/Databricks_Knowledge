# DWH_dbo.Dim_RedeemReason - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None - all columns are Tier 1 or Tier 2.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| RedeemReasonName ID 19 (FailedByDelta) | This ID exists in DWH but not in the upstream wiki (Dictionary.RedeemReason.md was written earlier). What is FailedByDelta? Does it relate to the Delta mobile app or the Delta trading product? |
| ID 17 gap | Why is ID 17 skipped in both production and DWH? Was there a deleted reason at ID 17? |

## Structural Questions

- **RedeemReasonID is nullable in DDL**: All PK-like columns in Dim_ tables sourced from SP_Dictionaries are nullable in Synapse DDL. Is this intentional (no NOT NULL support for REPLICATE tables in Synapse), or is it a DDL oversight?
- **DisplayName dropped**: Production DisplayName currently duplicates Name. If they diverge in future, should DisplayName be added to the DWH? Currently no business impact since values match.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
