# Review Needed: eMoney_dbo.eMoney_Dictionary_AuthorizationType

**Generated**: 2026-04-21 | **Batch**: 11 | **Object type**: Table (Dictionary, SIMPLE-DICT fast-path)

## Status

No critical Tier 4 items. Low-risk dictionary table with confirmed upstream source. Prior batch context (batch 4) had WRONG enum values — live MCP data used exclusively.

## Review Items

| # | Item | Severity | Notes |
|---|------|----------|-------|
| 1 | UpdateDate static since 2023-06-12 | INFO | Table has not been refreshed since initial load. Confirm Generic Pipeline is still scheduled for `External_FiatDwhDB_Dictionary_AuthorizationTypes`. |
| 2 | 0=Unknown sentinel | INFO | Unknown (ID=0) exists as sentinel. Confirm whether any production transaction records carry AuthorizationTypeID=0 and whether this is expected. |
| 3 | AuthorizeAdvice (10) excluded from financial totals | INFO | AuthorizeAdvice is a network advisory message, not a debit/credit. Confirm all financial aggregation queries exclude AuthorizationTypeID=10. |
| 4 | SysReversal (13) vs Reversal (12) distinction | INFO | SysReversal is system-initiated (timeout/error); Reversal is customer/merchant-initiated. Confirm dispute analysis queries filter these separately. |

## Reviewer Confirmation Needed

- [ ] Confirm Generic Pipeline schedule for `External_FiatDwhDB_Dictionary_AuthorizationTypes`
- [ ] Confirm no unintended financial aggregations include AuthorizationTypeID=10 (AuthorizeAdvice)
- [ ] Confirm SysReversal (13) is excluded from customer-initiated reversal counts

*Sidecar generated: 2026-04-21 | Quality: 9.2/10 | Phases completed: P1, P2, P4, P8, P10A, P10B, P11*
