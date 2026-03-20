# DWH_dbo.CustomerStatic -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

| Column | Issue | Question |
|--------|-------|----------|
| Amount | Meaning and units completely unknown - table has 0 rows | What was this column intended to store? Initial deposit amount? Account balance? Amount in units? |

## Columns Needing Clarification

| Column | Issue |
|--------|-------|
| ActionTypeID | Was this intended to always be 41 (Customer Registration) or could it hold other action type values? |
| PlatformTypeID | What dimension does this reference? Dim_Platform has PlatformID (0-3). Is PlatformTypeID a different dimension from PlatformID? Or was this a design error? |
| StatusID | Which status dimension does this reference? Dim_AccountStatus? Dim_PlayerStatus? Something else? |

## Structural Questions

1. **Was this table intentionally abandoned?** The table has 0 rows and no ETL SP writes to it. Was this a design that was superseded by Fact_FirstCustomerAction or Fact_CustomerAction ActionTypeID=41?
2. **Is this table safe to drop?** No views, SPs, or other tables reference it. If permanently abandoned, it could be candidates for blacklisting.
3. **PlatformTypeID vs PlatformID duality** - The table has both PlatformTypeID (int NOT NULL) and PlatformID (int NOT NULL). These appear to be different dimensions. What is the distinction?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
