# BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep_fulldata — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

| Column | Unverified Assumption | Why Uncertain |
|--------|----------------------|---------------|
| PlayerStatusReason | Described as coming from Dim_PlayerStatus.Reason | Column name is PlayerStatusReason but Dim_PlayerStatus may store this differently. Cannot fully verify without reading Dim_PlayerStatus DDL. |
| PlayerStatusSubReasonName | Described as coming from Dim_PlayerStatus.SubReasonName | Same uncertainty as PlayerStatusReason — exact column mapping in Dim_PlayerStatus not verified. |
| Liabilities | Described as "total net liabilities (deposits minus withdrawals)" | V_Liabilities definition not read. This is the common DWH definition but may differ for eMoney/wallet customers. |
| AccountProgram | Described as "account program classification" | Source is Dim_Customer.AccountProgram. Exact business meaning of program classification not found in SSDT or upstream wiki. |
| PhoneVerifiedName | Described as "phone-verified display name" | Not commonly documented. Could be the name used during phone verification (KYC matching) rather than the display name. |

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| Multiple rows per CID | A CID who shares 3 FundingIDs will appear 3 times. Is this the intended behavior for the AML team's tooling, or do analysts need to deduplicate CIDs before investigation? |
| V_Liabilities at @DateID | Liabilities, RealizedEquity, PositionPnL, TotalEquity are point-in-time at the SP's run date. If the SP is run infrequently, these financials may be significantly stale. How does the AML team handle this? |
| External_AlertServiceDB tables | The exact external table name(s) for the Alert Service enrichment are not visible in the SP. Are these External_AlertServiceDB_AlertDetails or similar? The DDL names should be confirmed to ensure the lineage is complete. |
| EvMatchStatusName | What does EvMatchStatusName = 'MatchFound' mean in the AML context? Does this indicate a positive EV match (good) or a potential fraud match (bad)? |

## Structural Questions

- With 265K rows and no index, this table relies on full scans. For investigation queries that JOIN to the 116K-row Dep table on FundingID, is performance acceptable? Would an index on FundingID or CID be beneficial?
- PII columns (UserName, BirthDate, Gender, City, Zip, BuildingNumber) are present in a table accessible to analysts. Is there a column-level masking policy in place, or is this relying on table-level access control?
- V_Liabilities is point-in-time. Should this table be re-run more frequently, or should it note the snapshot date explicitly in a column?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
