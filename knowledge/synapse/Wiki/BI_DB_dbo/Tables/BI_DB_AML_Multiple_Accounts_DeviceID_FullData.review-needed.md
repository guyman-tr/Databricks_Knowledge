# BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID_FullData — Review Needed

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
| TriggerType | Described as "what event triggered the alert" | External_AlertServiceDB TriggerType values not sampled in Phase 3. Content of this field is inferred from naming convention. |
| StatusReason | Described as "reason for current alert status" | Not sampled. Assumed based on column name and StatusType semantics. Could be free text or a lookup value. |

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| CID deduplication risk | A CID who shares 3 devices will appear 3 times, each row showing the same latest alert. Analysts aggregating by CID (e.g., COUNT of active-alert customers) must use COUNT(DISTINCT CID). Is this a known issue in existing dashboards using this table? |
| External_AlertServiceDB schema | The SP references External_AlertServiceDB tables for alert enrichment. The exact table names within AlertServiceDB are not visible in the SP alias. Please confirm: which production table within AlertServiceDB is the source for AlertType, CategoryName, StatusType? |
| 62% NULL alerts | 62% of rows (1.53M) have no alert record. Does this mean these customers genuinely have no alerts, or is there an alert data coverage gap? Could the Alert Service miss customers who have never triggered any alert system? |
| Alert deduplication by ModificationDate | Latest alert is selected by most-recent ModificationDate. Is this the correct recency signal? Some SPs use CreationDate or a specific alert priority rank. |

## Structural Questions

- 2.5M rows with no index on a HEAP table. Complex queries (JOIN to DWH fact tables) may be slow. Would partitioning or indexing on CID help?
- For analysts investigating a specific device, they must JOIN back to BI_DB_AML_Multiple_Accounts_DeviceID on ClientDeviceId to get the group count. Would it be useful to include NumOfClientsSameDeviceID directly in this table?
- Given that a CID can appear multiple times (once per shared device), is there a risk of alert overcounting in reporting tools that don't deduplicate? Have dashboards been audited for this?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
