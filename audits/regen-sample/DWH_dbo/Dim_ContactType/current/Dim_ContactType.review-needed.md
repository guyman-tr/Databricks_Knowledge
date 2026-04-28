# DWH_dbo.Dim_ContactType — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

| Column | Issue | Evidence Checked |
|--------|-------|-----------------|
| Name | 0 rows in table — cannot confirm actual values. Inferred to be short contact category labels (Email, Phone, Chat, etc.) from column name alone. | SSDT DDL, SP_Dictionaries, DWH_Migration scripts, DB_Schema etoro — all returned no results. |

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| Name | What are the intended contact type values? Is this for customer contact channel classification, CRM contact categories, or something else? |
| DWHContactTypeID | Standard DWH surrogate pattern — should this equal ContactTypeID when populated, or is there a different mapping? |
| StatusID | Bit flag — confirm: 1=active, 0=inactive, NULL=never loaded? |

## Structural Questions

1. **Completely empty and unknown**: This table has 0 rows, no ETL, and no production equivalent found anywhere. Should this table be dropped from the schema, or is there a planned ETL implementation?
2. **Planned SP_Dictionaries integration**: The DWHContactTypeID surrogate column strongly suggests this was designed to be loaded by SP_Dictionaries_DL_To_Synapse. Was there a Dictionary.ContactType table in the etoro production DB? What happened to the ETL section that would load it?
3. **Not in Generic Pipeline**: This table is not exported to Gold/UC. If it is ever populated, a Generic Pipeline entry should be added.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
