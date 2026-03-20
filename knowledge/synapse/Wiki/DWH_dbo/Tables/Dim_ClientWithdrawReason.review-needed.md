# DWH_dbo.Dim_ClientWithdrawReason - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns. All elements confirmed via upstream wiki and ETL SP code.

## Columns Needing Clarification

None.

## Structural Questions

- **IsActive and DisplayOrder dropped**: The production Dictionary.ClientWithdrawReason has IsActive and DisplayOrder columns that control UI visibility and ordering. These are not in the DWH. Should they be added for analysts who need to know which reasons are currently UI-visible?
- **Nullable PK**: The DWH DDL defines ClientWithdrawReasonID as nullable (int NULL), while production has it as NOT NULL. Is this a DDL migration artifact or intentional?
- **Free-text reason storage**: ID=1 "None of the reasons above" is the fallback. The accompanying free-text comment (ClientWithdrawReasonComment) is stored on Billing.Withdraw/Fact_BillingWithdraw. Confirm this field is being captured in the fact table ETL.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
