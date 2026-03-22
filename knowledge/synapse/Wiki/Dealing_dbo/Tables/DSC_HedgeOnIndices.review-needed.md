# Dealing_dbo.DSC_HedgeOnIndices — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all descriptions derived from SP code analysis (Tier 2).

## Columns Needing Clarification

| Column / Topic | Question | Evidence |
|----------------|----------|----------|
| Zero | Recent data (2026-03-11) shows all zeros for all instruments — is this expected? Has the hedge strategy been deactivated or moved to a different reporting table? | Live sample: all 4 instruments show Zero=0, HC_ALL=0, TheoreticalBoundaryCost=0, SpreadLPBoundary=0 |
| HedgeServerID | SP filters `HedgeServerID IN (222, 21)` — are these the only relevant hedge servers for indices? Are additional servers used for other asset types? | SP code line: `hp.IsSettled=r.Isreal and HedgeServerID in (222,21)` |
| @spread | The fixed spread factor `0.00004125` is hardcoded in the SP — is this still the correct LP boundary spread? When was it last updated? | SP code: `SET @spread=0.00004125` |

## Structural Questions

| Question | Context |
|----------|---------|
| Is DSC_HedgeOnIndices_H (hourly detail) also consumed by external dashboards or reports, or only as an intermediate for this daily aggregate? | SP writes to _H first, then aggregates to this table |
| The table name prefix "DSC_" appears unique — does it stand for "Dealing System Cost" or another abbreviation? | Only 2 tables use this prefix: DSC_HedgeOnIndices, DSC_HedgeOnIndices_H |

## Tier 5 Re-Review Needed

> No items requiring re-review.

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
