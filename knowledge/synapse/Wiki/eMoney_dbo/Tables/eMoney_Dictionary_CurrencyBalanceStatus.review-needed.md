# Review Needed: eMoney_dbo.eMoney_Dictionary_CurrencyBalanceStatus

**Generated**: 2026-04-21 | **Batch**: 11 | **Object type**: Table (Dictionary, SIMPLE-DICT fast-path)

## Status

No critical Tier 4 items. Low-risk dictionary table with confirmed upstream source. Prior batch context (batch 4) had WRONG enum values — live MCP data used exclusively.

## Review Items

| # | Item | Severity | Notes |
|---|------|----------|-------|
| 1 | UpdateDate static since 2023-06-12 | INFO | Table has not been refreshed since initial load. Confirm Generic Pipeline is still scheduled for `External_FiatDwhDB_Dictionary_CurrencyBalanceStatuses`. |
| 2 | ReceiveOnly (1) and SpendOnly (2) partial restriction | INFO | These allow one direction of movement and should NOT be grouped with Suspended/Blocked in "fully restricted" counts. Confirm metric definitions are correct. |
| 3 | String match: 0=Active not 0=Open | INFO | Active balance status is "Active" not "Active/Open". Confirm filters use exact string. |

## Reviewer Confirmation Needed

- [ ] Confirm Generic Pipeline schedule for `External_FiatDwhDB_Dictionary_CurrencyBalanceStatuses`
- [ ] Confirm "fully restricted balance" queries use CurrencyBalanceStatusID IN (3,4) not IN (1,2,3,4)
- [ ] Confirm no compliance dashboards incorrectly group ReceiveOnly/SpendOnly with Suspended/Blocked

*Sidecar generated: 2026-04-21 | Quality: 9.2/10 | Phases completed: P1, P2, P4, P8, P10A, P10B, P11*
