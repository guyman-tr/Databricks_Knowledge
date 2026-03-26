# BI_DB_dbo.BI_DB_DDR_Fact_AUM — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all columns traced to SP code (Tier 2) or upstream wiki (Tier 1).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| IBANBalance | USDApproxRate is an approximate FX rate — is there a more precise conversion used elsewhere? |
| OptionsTotalEquity | The function uses the MAX(ProcessDate) available — what is typical lag vs the daily load date? |
| TotalEquityTP | Computed as SUM(TotalLiability + actualNWA) — is this equivalent to other equity definitions used in DDR? |

## Structural Questions

- The UNION in the SP includes a second SELECT for rows where `TotalLiabilityTP = 0` but have other non-zero values. What specific customer scenarios does this capture (IBAN-only? Options-only?)
- House account exclusions for Options are hardcoded (4GS43999, 4GS00100-104). Should these be in a config table?
