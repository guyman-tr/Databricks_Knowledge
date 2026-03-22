# Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all columns traced to SP code or upstream wiki.

## Columns Needing Clarification

| Column | Question | Evidence |
|--------|----------|----------|
| HaseMoneyAccount | Is the typo intentional? Should this be renamed to HasEMoneyAccount? | Column name has "Hase" in DDL and SP. SP comment in Hebrew suggests it was intentional. |
| IsLowTouch | What exactly does Dim_Instrument.OperationMode represent? | Column renamed from OperationMode. Only 0/1 values observed. |
| IsFTDClick | Is this flag only for non-AirDrop opens, or should AirDrop FTDs also be flagged? | SP explicitly sets IsFTDClick=0 for AirDrop opens in #OpenClickesAirDrop. |
| HedgeServerID=35 | Why are invalid customers included for HedgeServerID=35? | SP condition: `dc.IsValidCustomer=1 OR (dc.IsValidCustomer=0 AND dp.HedgeServerID=35)`. Added SR-331129. |

## Structural Questions

| Question | Context |
|----------|---------|
| What is the intended consumer of this table? | No downstream references found in SSDT. Likely consumed by Tableau dashboards or ad-hoc dealing analysis. |
| What is the refresh schedule? | SP takes @Date parameter (typically yesterday). Is it run by Service Broker? If so, at what priority/time? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
