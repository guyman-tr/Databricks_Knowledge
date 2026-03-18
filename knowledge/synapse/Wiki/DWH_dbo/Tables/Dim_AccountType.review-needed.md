# DWH_dbo.Dim_AccountType — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all elements have Tier 1 or Tier 2 confidence.

## Columns Needing Clarification

- **DWHAccountTypeID**: Confirmed redundant (= AccountTypeID) from SP code. Is there any downstream consumer that uses DWHAccountTypeID instead of AccountTypeID? If so, which?

## Structural Questions

- **Trust (ID=18)**: Appears in live data but not in the upstream production wiki's list (which goes to 17). Is Trust a recently added account type? Was the production wiki outdated at extraction time?
- **DWH consumer coverage**: The "Referenced By" section lists Dim_Customer and Fact_SnapshotCustomer. Are there additional DWH tables that JOIN on AccountTypeID?

## Tier 5 Re-Review Needed

_No Tier 5 overrides exist for this object._
