# Review Needed: eMoney_dbo.eMoney_Dictionary_CardStatus

**Generated**: 2026-04-21 | **Batch**: 11 | **Object type**: Table (Dictionary, SIMPLE-DICT fast-path)

## Status

No critical Tier 4 items. Low-risk dictionary table with confirmed upstream source. Prior batch context (batch 4) had WRONG enum values — live MCP data used exclusively.

## Review Items

| # | Item | Severity | Notes |
|---|------|----------|-------|
| 1 | UpdateDate static since 2023-06-12 | INFO | Table has not been refreshed since initial load. Confirm Generic Pipeline is still scheduled for `External_FiatDwhDB_Dictionary_CardStatuses`. |
| 2 | Terminal states (5, 6, 7, 8) exclusion | INFO | Stolen, Lost, Expired, Fraud are terminal — no reactivation possible. Confirm active-card counts exclude CardStatusID IN (5,6,7,8). |
| 3 | Risk (4) vs Suspended (3) distinction | INFO | Risk is risk-engine triggered; Suspended is compliance/review-triggered. Confirm compliance reporting distinguishes these. |
| 4 | String match: 1=Activated not 1=Active | INFO | Column value is "Activated" not "Active". Confirm all string-based status filters use the correct spelling. |

## Reviewer Confirmation Needed

- [ ] Confirm Generic Pipeline schedule for `External_FiatDwhDB_Dictionary_CardStatuses`
- [ ] Confirm active-card metric queries exclude terminal states (5, 6, 7, 8)
- [ ] Confirm Risk (4) and Suspended (3) are handled separately in compliance dashboards

*Sidecar generated: 2026-04-21 | Quality: 9.2/10 | Phases completed: P1, P2, P4, P8, P10A, P10B, P11*
