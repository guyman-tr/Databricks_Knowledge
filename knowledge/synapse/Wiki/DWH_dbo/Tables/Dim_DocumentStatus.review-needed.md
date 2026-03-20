# DWH_dbo.Dim_DocumentStatus - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 [UNVERIFIED] columns in this document.

## Columns Needing Clarification

| Column / Topic | Question |
|----------------|----------|
| Referenced By | Which fact table(s) reference DocumentStatusID? Please confirm the downstream fact table name (e.g., Fact_KYCDocuments or similar). |
| POIApproved vs Accepted | Is POIApproved (ID=5) mutually exclusive with Accepted (ID=3), or can a document be both? What is the final "approved" state for: identity (ID=5 or ID=3?), address (ID=6 or ID=3?)? |
| ID=2 (Reviewed) | Is ID=2 an intermediate state always followed by Accepted/Rejected, or can it be a terminal state? |

## Structural Questions

| Question |
|----------|
| Does the production etoro.Dictionary.DocumentStatus have exactly these 7 rows, or are there additional states not yet in DWH? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
