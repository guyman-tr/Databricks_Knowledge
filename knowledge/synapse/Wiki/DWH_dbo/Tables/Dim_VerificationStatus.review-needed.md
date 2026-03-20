# DWH_dbo.Dim_VerificationStatus -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns. However, the following columns are Tier 3 (live data only, no upstream wiki):

| Column | Current Description | Question |
|--------|-------------------|----------|
| VerificationStatusID | "Numeric identifier for the verification workflow status from UserApiDB" | What are the actual ID values and their business meanings? |
| Name | "Human-readable label for the verification status" | What are the 3 status names and their business meaning in the UserApiDB workflow? |

## Columns Needing Clarification

1. **VerificationStatusID values**: No upstream wiki for UserApiDB.Dictionary.VerificationStatus. The 3 live row values and their Name labels need domain expert confirmation to provide Tier 1 descriptions.
2. **Relationship to Dim_VerificationLevel**: These are distinct concepts (workflow state vs. KYC tier). Which DWH fact or dim tables join to this dimension? The downstream consumers were not identified during documentation.

## Structural Questions

1. **Source database**: This dimension comes from UserApiDB, not etoroDB. Verify the Generic Pipeline source database connection and lake path are correct.
2. **No ETL placeholder row**: Unlike most DWH Dims, no ID=0 or ID=-1 sentinel is added. Confirm fact tables handle NULL VerificationStatusID without a placeholder.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
