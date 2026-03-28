# BI_DB_dbo.BI_DB_AML_Documents_Dashboard — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all 23 elements are Tier 1 or Tier 2.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| DocumentStatus | This comes from External_etoro_BackOffice_Customer.DocumentStatusID (the customer's overall doc status), not per-document. Is this intentional, or should it be per-document status from the CustomerDocumentToDocumentType table? |
| ClassifiedBy (hardcoded list) | The 23-name filter is hardcoded. Is this the current AML team roster? If staff have changed, the data may be incomplete. |
| ClassificationOccured | Column name has a typo ("Occured"). Is this intentional to match the production schema, or a bug in the SP? |

## Structural Questions

- The table has no PK or index. Would adding a CLUSTERED INDEX on (CID, DocumentAdded) improve query patterns?
- The varchar(500) columns (Gender, Regulation, PlayerStatus, Club, etc.) are vastly over-sized for the actual data. Is this intentional for compatibility with external table definitions?
- The table is fully rebuilt daily (TRUNCATE + INSERT). Could this be incremental to reduce ETL cost, or is full rebuild necessary because external tables don't support incremental watermarks?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
