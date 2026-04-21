# Review Needed: eMoney_dbo.eMoney_Dictionary_AccountStatus

**Generated**: 2026-04-20 | **Batch**: 8 | **Object type**: Table (Dictionary, SIMPLE-DICT fast-path)

## Status

No critical Tier 4 items. Low-risk dictionary table with confirmed upstream source.

## Review Items

| # | Item | Severity | Notes |
|---|------|----------|-------|
| 1 | UpdateDate static since 2023-06-12 | INFO | Table has not been refreshed since initial load. Confirm Generic Pipeline is still scheduled. |
| 2 | 2=Deleted vs IsCancelledAccount | INFO | eMoney_Dim_Account uses IsCancelledAccount flag for GCID=0 accounts; Deleted (ID=2) in this dictionary may not fully align. Confirm the mapping between AccountStatusID=2 and IsCancelledAccount=1. |

## Reviewer Confirmation Needed

- [ ] Confirm AccountStatusID=2 (Deleted) maps 1:1 with IsCancelledAccount=1 in eMoney_Dim_Account
- [ ] Confirm Generic Pipeline schedule for `External_FiatDwhDB_Dictionary_AccountStatuses`

*Sidecar generated: 2026-04-20 | Quality: 9.1/10 | Phases completed: P1, P2, P4, P8, P10A, P10B, P11*
